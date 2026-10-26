import io
import os
import logging
from pathlib import Path

import joblib
import pandas as pd
import requests
import numpy as np

from client_convex import get_client_url
from cloud_model import PXRFModel
from ebk_predict import dataframe_to_grid
from gbdt_model_renewed import PXRFMaterialClassifier
from tempfile import TemporaryDirectory

logger = logging.getLogger(__name__)

#Get Job Function
def get_prediction_params(job_id, project_id):

  job = client.query( "batch:getPredictionJobParameters", 
                     {"jobId": job_id, "projectId": project_id})

  if job is None:
    raise ValueError("Job could not be found")

  return job

#Upload URLS from the API
def ret_upload_url(job_id):
  
  uploadUrl = client.mutation("batch:getPredictionJobResultsUploadUrl", { "jobId": job_id })
  
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

    if df.empty:
      raise ValueError("pXRF CSV is Empty")

    #Store which unit this came from
    df["source_unit_index"] = index
    
    coords = ["X_Coord", "Y_Coord"]
    #ensure the coords are present in the file
    if not all(col in df.columns for col in coords):
      raise ValueError("CSV has no XY coordinates")
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
  coords =  result_data_frame[["X_Coord", "Y_Coord"]]
  #Make sure the coordinates are real and finite
  valid = np.isfinite(coords.to_numpy(dtype=float)).all(axis=1)
  #Use only the valid points in the EBK 
  location_data = result_data_frame.loc[valid].copy()

  if location_data.empty:
    raise ValueError("No valid coordinates available for EBK")

  unique_points = location_data[["X_Coord", "Y_Coord"]].drop_duplicates()
  
  if len(unique_points) < 10:
    raise ValueError("Need at least 10 distinct sample locations")

  
  print(f"Total Unit Samples: {len(result_data_frame)}")
  print(f"Located Unit Samples: {len(location_data)}")

  #Run the EBK interpolation
  ebk_grid_df, origin_points_df = (
        dataframe_to_grid(
            location_data,
            x_col="X_Coord",
            y_col="Y_Coord",
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
  job_ready = client.query("projects:getPredictionJobStatus",
                           {
                             "jobId": job_id,
                              "projectId": project_id
                           }
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
  client.mutation("batch:completePredictionJob",
                  {"jobId": job_id,
                   "projectId": project_id,
                   "storageId": storage_id
                  })

#Add job_failed function for failed jobs

def job_failed(job_id, project_id):
  client.mutation("batch:failPredictionJob",
                  {
                    "jobId": job_id,
                    "projectId": project_id
                  }
                 )
#Once the claimed the Job can be ran
#from starting -> running
def claim_job(job_id, project_id):
  is_claimed = client.mutation( "batch:claimPredictionJob", 
                     {"jobId": job_id, "projectId": project_id})

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
