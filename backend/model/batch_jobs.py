import io
import os
import logging
from pathlib import Path

import joblib
import pandas as pd
import requests

from convex_client import client
from cloud_model import PXRFModel
from ebk_predict import dataframe_to_grid
from gbdt_model_renewed import PXRFMaterialClassifier
from tempfile import TemporaryDirectory

GATEWAY_URL = ""
GATEWAY_TOKEN = ""
logger = logging.getLogger(__name__)

#Get Job Function
def get_job(job_id):

  job = client.query( "batch:get_job", {"job_id": job_id})

  if job is None:
    raise ValueError("Job could not be found")

  return job

#Upload URLS from the API
def ret_upload_url(job_id):
  
  uploadUrl = client.query("batch:getPredictionJobOutputUploadUrl", { "jobId": job_id })
  
  return uploadUrl

#Retrieve CSV function
def download_csv(url):
  
  response = requests.get(url, timeout=(10, 120))

  response.raise_for_status()

  return pd.read_csv(io.BytesIO(response.content))


#Load the Data
def load_data(job):
  
  input_files = job["input_files"]
  
  dataframes = []
  
  if not input_files:
    raise ValueError("Job has no input files")

  for input_file in input_files:
        data_f = download_csv(input_file["url"])

        if data_f.empty:
            raise ValueError("Input CSV is empty")

        dataframes.append(data_f)
  
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
def upload_to_convex(kind, job_id, output):
  
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
  #Save the reference of the file
  client.mutation(
    "batch:setPredictionJobOutputStorageId",
    {
      "jobId": job_id,
      "storageId": storage_id
    }
  )
  
  return {
    "name": output["name"],
    "filename": output["filename"],
    "storage_id": storageId
  }

#Process the Job Using previous functions
def process_job(model, job_id):
  job = get_job(job_id)
  #Ensure that only starting jobs are processed
  if job["status"] != "starting":
    raise ValueError(
      "Job must be in starting status"
    )
  #TODO: Initialize claim_job to change job status
  claim_job(job_id)
  
  try:
    data_frame = load_data(job)
    #Store the operation
    kind = job["kind"]
    #Determine which opertaion to run
    if kind == "prediction":
      output = run_prediction(data_frame, model)

    elif kind == "training":
      output = train_model(data_frame)
    
    else:
      raise ValueError(f"Unknown Job Field Kind: {kind}")

    uploads = []

    for outs in output:
      uploads.append(upload_to_convex(
        job_id,
        kind,
        outs))
    #Mark as Complete and Log
    #complete_job(uploads, job_id)
    
    logger.info("Job %s completed successfully",job_id)
    
    return {
      "job_id": job_id,
      "status": "complete",
      "outputs": uploads
    }
  #Log in the event a Job fails with its ID  
  except Exception as error:
    logger.exception("Job %s failed",job_id)
    try:
      job_failed(job_id,error)
      
    except Exception:
      logger.exception("Could not mark job as failed")

    raise

  
#Update the Job to Finished
#def complete_job(uploaded_files, job_id):
# client.mutation("batch:completeJob",{"jobId": job_id,"outputs": uploaded_files})

#Add job_failed function for failed jobs

def job_failed(job_id, error):
  client.mutation("batch:failJob",
                  {
                    "jobId": job_id,
                    "error": type(error).__name__
                  }
                 )
#Once the claimed the Job can be ran
#from starting -> running
def claim_job(job_id):
  is_claimed = client.mutation("batch:claimJob",{"jobId": job_id})

  if is_claimed is not True:
    raise ValueError("Job could not be claimed")

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
