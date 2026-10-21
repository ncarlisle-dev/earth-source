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
