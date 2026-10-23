import io
import os
import logging
from pathlib import Path

import joblib
import pandas as pd
import requests

from client_convex import client
from cloud_model import PXRFModel
from ebk_predict import dataframe_to_grid
from gbdt_model_renewed import PXRFMaterialClassifier
from tempfile import TemporaryDirectory

logger = logging.getLogger(__name__)

#Get Job Function
def get_job(job_id, project_id):

  job = client.query( "batch:getPredictionJobById", 
                     {"jobId": job_id, "projectId": project_id})

  if job is None:
    raise ValueError("Job could not be found")

  return job

#Upload URLS from the API
def ret_upload_url(job_id):
  
  uploadUrl = client.query("batch:getPredictionJobResultsUploadUrl", { "jobId": job_id })
  
  return uploadUrl

#Retrieve CSV function
def download_csv(url):
  
  response = requests.get(url, timeout=(10, 120))

  response.raise_for_status()

  return pd.read_csv(io.BytesIO(response.content))


#Load the Data
def load_data(job, project_id):
  
  assignments = job["dataAssignments"]
  
  dataframes = []
  
  for unit_id, spec_id in assignments.items():
    if spec_id is None:
      continue

    url = client.query(
      "projects:getProjectPxrfDataUrl",
      {
        "projectId": project_id,
        "specId": spec_id
      })
    
    dframe = download_csv(url)
    
    if dframe.empty:
      raise ValueError(f"CSV for unit {unit_id} is empty")

    dataframes.append(dframe)
    
  if not dataframes:
    raise ValueError("Prediction job has no assigned pXRF data")

  return pd.concat( dataframes, ignore_index=True)

#Run the Classifier and EBK
def run_prediction(df, model):
  result_data_frame = model.predict(df)
  
  ebk_grid_df, origin_points_df = (
        dataframe_to_grid(
            result_data_frame,
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
  #Ensure that what the user wants is specified
  if output_name not in ["classification", "ebk"]:
    raise ValueError("Output must be either classification or ebk")
  
  job = get_job(job_id, project_id)
  #Ensure that only starting jobs are processed
  if job["status"] != "starting":
    raise ValueError("Job must be in starting status")
  #TODO: Initialize claim_job to change job status
  claim_job(job_id, project_id)
  
  try:
    data_frame = load_data(job,project_id)
    
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
