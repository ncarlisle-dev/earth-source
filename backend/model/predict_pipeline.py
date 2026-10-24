from cloud_model import PXRFModel
from ebk_predict import dataframe_to_grid

#Load in trained model for each process
model = PXRFModel("pxrf_full_model.pkl")

#This pipeline file will help the job_worker
#Elimate the need to call EBK twice

def classify_samples(dataframe):
  return model.predict(dataframe)

#Take in samples with coordinates
#Return the EBK grid
def process_samples(dataframe):
  req = {"X_Coord", "Y_Coord"}

  is_missing = required - set(df.columns)

  if missing:
    raise ValueError(f"Missing coordinates: {sorted(missing)}")
  #Run the GBDT Classifier
  classified_dataframe = classify_samples(dataframe)
  #Run EBK predictions on the classified data
  grid_df, original_points_df = dataframe_to_grid(
    classified_dataframe,
    x_col="X_Coord",
    y_col="Y_Coord",
    prob_col="non_soil_probability"
  )
  #return the processed data
  return classified_dataframe, grid_df
  
