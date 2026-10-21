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
def get_job(job_id)
#Upload URLS from the API
def ret_upload_url()
#Retrieve CSV function
def download_csv()
#Load the Data
def load_data()
#Run the Classifier and EBK
def run_prediction()
#Upload Output File
def upload_to_convex()
#Process the Job Using previous functions
def process_job()
#Update the Job to Finished
def complete_job()
#Train if Necessary
def train_model()
