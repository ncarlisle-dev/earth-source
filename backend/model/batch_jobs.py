import io
import os
import logging
from pathlib import Path

import math
import joblib
import pandas as pd
import requests
import numpy as np

from pyproj import Transformer
from client_convex import get_client_url
from cloud_model import PXRFModel
from ebk_predict import dataframe_to_grid
from gbdt_model_renewed import PXRFMaterialClassifier
from tempfile import TemporaryDirectory

logger = logging.getLogger(__name__)
#create client connection
client = get_client_url(os.environ["CONVEX_URL"])

#Constants for Coordinates
X_COORD = "X_Coord"
Y_COORD = "Y_Coord"

COORD_COLUMNS = [X_COORD, Y_COORD]

#Get Job Function
def get_prediction_params(job_id, project_id):
  job = client.query(
    "batch:getPredictionJobParameters", 
    {"jobId": job_id, "projectId": project_id}
  )

  if job is None:
    raise ValueError("Job could not be found")

  return job

#Upload URLS from the API
def ret_upload_url(job_id):
  uploadUrl = client.mutation(
    "batch:getPredictionJobResultsUploadUrl", 
    { "jobId": job_id }
  )
  
  return uploadUrl

#Retrieve CSV function
def download_csv(url):
  response = requests.get(url, timeout=(10, 120))

  response.raise_for_status()

  return pd.read_csv(io.BytesIO(response.content))


#Load the Data
def load_data(params):
  #assignments = job["dataAssignments"]
  #TODO 107: Use the parameters given with the project
  return_df = []
  
  for index, unit in enumerate(params["unitMetadata"]):
    df = download_csv(unit["dataDownloadUrl"])
    #test to check for csv data
    print("Downloaded CSV columns:")
    print(df.columns.tolist())

    print("First 3 rows:")
    print(df.head(3).to_string())

    if df.empty:
      raise ValueError("pXRF CSV is Empty")

    #Store which unit this came from
    df["source_unit_index"] = index
    
    coords = ["X_Coord", "Y_Coord"]
    #ensure the coords are present in the file
    if not all(col in df.columns for col in coords):
      print(f"Mapping sample coords for unit {index}")
      df = assign_coords(df,unit,params["siteCorners"])
      
    else:
      #Convert coords to actual numeric values
      for col in coords:
        df[col] = pd.to_numeric(df[col],errors="coerce")

    
    return_df.append(df)

  if not return_df:
    raise ValueError("No pXRF data assigned")

  return pd.concat(return_df, ignore_index=True)

#Run the Classifier and EBK
def run_prediction(df, model):
  #Run the classifieer
  result_data_frame = model.predict(df)
  #Take in samples with validated coordinates
  coords =  result_data_frame[COORD_COLUMNS]
  #Make sure the coordinates are real and finite
  valid = np.isfinite(coords.to_numpy(dtype=float)).all(axis=1)
  #Use only the valid points in the EBK 
  location_data = result_data_frame.loc[valid].copy()

  if location_data.empty:
    raise ValueError("No valid coordinates available for EBK")

  unique_points = location_data[COORD_COLUMNS].drop_duplicates()
  
  if len(unique_points) < 10:
    raise ValueError("Need at least 10 distinct sample locations")

  print(f"Total Unit Samples: {len(result_data_frame)}")
  print(f"Located Unit Samples: {len(location_data)}")

  #Run the EBK interpolation
  ebk_grid_df, origin_points_df = (
        dataframe_to_grid(
            location_data,
            x_col=X_COORD,
            y_col=Y_COORD,
            prob_col="non_soil_probability"
        )
  )
  
  return [
    {
      "name": "classification",
      "filename": "ArchaeoSight_Results.csv",
      "content": result_data_frame.to_csv(index=False).encode("utf-8"),
      "contentType": "text/csv"},
    {
      "name": "ebk",
      "filename": "ArchaeoSight_EBK_Grid.csv",
      "content": ebk_grid_df.to_csv(index=False).encode("utf-8"),
      "contentType": "text/csv"
    }
  ]
#Upload Output File
def upload_to_convex(job_id, output):
  upload_url = ret_upload_url(job_id)
  
  response = requests.post(
    upload_url,
    data=output["content"],
    headers={"Content-Type": output["contentType"]},
    timeout=(10, 60)
  )
  
  response.raise_for_status()
  #Receive the file's identifier
  storage_id = response.json()["storageId"]
  
  return storage_id

#Process the Job Using previous functions
def process_job(model, job_id, project_id, output_name="classification"):
  #Validate the requested output name
  if output_name not in ["ebk", "classification"]:
        raise ValueError("Output must be classification or ebk")
    
  #Ensure the job is ready
  job_ready = client.query(
    "projects:getPredictionJobStatus",
    {"jobId": job_id,"projectId": project_id}
  )
  
  #Ensure that only starting jobs are processed
  if job_ready != "starting":
    raise ValueError("Job must be in starting status")

  params = get_prediction_params(job_id,project_id)
  
  #TODO: Initialize claim_job to change job status
  claim_job(job_id, project_id)
  
  try:
    data_frame = load_data(params)
    
    outputs = run_prediction(data_frame, model)

    select_one_output = next(
      output for output in outputs
      if output["name"]==output_name
    )
    storage_id = upload_to_convex(job_id, select_one_output)
    complete_job(job_id, project_id, storage_id)
    
    logger.info("Job %s completed successfully",job_id)
    
    return {
      "job_id": job_id,
      "projectId": project_id,
      "status": "complete",
      "filename": select_one_output["filename"],
      "storageId": storage_id
    }
    
  #Log in the event a Job fails with its ID  
  except Exception as error:
    logger.exception("Job %s failed",job_id)
    try:
      job_failed(job_id,project_id)
      
    except Exception:
      logger.exception("Could not mark job as failed")

    raise

#Update the Job to Finished
def complete_job(job_id, project_id, storage_id):
  client.mutation(
    "batch:completePredictionJob",
    {"jobId": job_id,
     "projectId": project_id,
     "storageId": storage_id
    }
  )

#Add job_failed function for failed jobs
def job_failed(job_id, project_id):
  client.mutation(
    "batch:failPredictionJob",
    {"jobId": job_id,"projectId": project_id}
  )
#Once the claimed the Job can be ran
#from starting -> running
def claim_job(job_id, project_id):
  is_claimed = client.mutation(
    "batch:claimPredictionJob",
    {"jobId": job_id, "projectId": project_id}
  )
  
#Train if Necessary
#Return the pkl model file
def train_model(df):
  with TemporaryDirectory() as folder:
    training_path = (Path(folder)/"training_data.csv")

    df.to_csv(training_path, index=False)

    classifier = PXRFMaterialClassifier()

    x, y = classifier.load_and_prepare_data(training_path)

    x_train, x_test, y_train, y_test = (classifier.train_test_by_materials(x, y))

    classifier.train_model(x_train,y_train)

    buffer = io.BytesIO()

    joblib.dump(classifier, buffer)

    model_in_bytes = buffer.getvalue()
  
  return [{
    "name": "model",
    "filename": "trained_model.pkl",
    "content": model_in_bytes,
    "contentType": "application/octet-stream"
  }]

#Address file inputs with no coordinates
def assign_coords(df, unit, site_corners):
  latitude = sum(
        p["latitude"] for p in site_corners)/len(site_corners)

  longitude = sum(
    p["longitude"] for p in site_corners)/len(site_corners)

  zone = min(60, max(1, int((longitude + 180) // 6) + 1))

  epsg = (32600 if latitude >= 0 else 32700) + zone

  transformer = Transformer.from_crs(
    "EPSG:4326",
    f"EPSG:{epsg}",
    always_xy=True)

  corners = [transformer.transform(p["longitude"], 
    p["latitude"]) for p in unit["corners"]]

  top_left, top_right, bot_left, bot_right = corners
  #Convert to centimeters
  interval = float(unit["pointInterval"])/100.0

  width = math.dist(top_left, top_right)
  height = math.dist(top_left, bot_left)

  if interval <= 0 or width <= 0 or height <= 0:
    raise ValueError("Invalid geometry")

  columns = math.floor(width / interval + 1e-9) + 1
  rows = math.floor(height / interval + 1e-9) + 1

  capacity = rows * columns

  if len(df) > capacity:
    raise ValueError(
      f"CSV has {len(df)} rows, but unit grid "
      f"has only {capacity} positions")

  x_coords = []
  y_coords = []

  for i in range(len(df)):
    row, col = divmod(i, columns)
    #Retrieve the weight of the vertical(vt) and horizontal (hz)
    hz = col * interval / width
    vt = row * interval / height
    #bilinear interpolation assignmnents (explanation later)
    #Assigns locations for EBK, EBK != Bilinear interpolation
    x = ((1-hz)*(1-vt)*top_left[0] + hz*(1-vt)*top_right[0] +
         hz*vt*bot_right[0] + (1-hz)*vt*bot_left[0])

    y = ((1-hz)*(1-vt)*top_left[1] + hz*(1-vt)*top_right[1] + 
         hz*vt*bot_right[1] + (1-hz)*vt*bot_left[1])

    x_coords.append(x)
    y_coords.append(y)

  result = df.copy()

  result[X_COORD] = x_coords
  result[Y_COORD] = y_coords

  return result

  
    
    
