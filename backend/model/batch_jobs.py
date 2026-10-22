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

#Get Job Function
def get_job(job_id):

  job = client.query( "batch:get_job", {"job_id": job_id})

  if job is None:
    raise ValueError("Job could not be found")

  return job

#Upload URLS from the API
def ret_upload_url(kind,job_id):
  endpoint = {
        "prediction": "getPredictionOutputUrl",
        "training": "getTrainingUrl"
    }[kind]
  
  response = requests.get(
        f"{GATEWAY_URL}/{endpoint}",
        params = {"jobId": job_id},
        headers = {
            "Authorization": f"Bearer {GATEWAY_TOKEN}"
        },
        timeout = 10
  )
  
  response.raise_for_status()
  
  return response.json()["uploadUrl"]
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
  
  upload_url = get_upload_url(job_id, kind)
  
  response = requests.post(
    upload_url,
    data=output["content"],
    headers={"Content-Type": output["content_type"]},
    timeout=(10, 60)
  )
  
  response.raise_for_status()
  
  return {
    "name": output["name"],
    "filename": output["filename"],
    "storage_id": response.json()["storage_id"]
  }

#Process the Job Using previous functions
def process_job()
#Update the Job to Finished
def complete_job(uploaded_files, job_id):
  client.mutation("batch:completeJob",{"jobId": job_id,"outputs": uploaded_files})

#Train if Necessary
def train_model()
