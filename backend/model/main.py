from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
import pandas as pd
import io

#testing import to prove Render Connection
from client_convex import client

from cloud_model import PXRFModel, FEATURE_COLUMNS
from ebk_predict import dataframe_to_grid
from batch_jobs import process_job

app = FastAPI()

model = PXRFModel("pxrf_full_model.pkl")

@app.get("/")
def root():
    return {"status": "The ArchSight is now running"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):

    contents = await file.read()

    df = pd.read_csv(io.BytesIO(contents))

    df.columns = df.columns.str.strip()

    available = [col for col in FEATURE_COLUMNS if col in df.columns]

    if not available:
        raise HTTPException(
            status_code=422,
            detail="No recognized pXRF element columns")

    #Identify scans containing valid measurements
    valid_scans = (
        df[available]
        .apply(pd.to_numeric, errors="coerce")
        .notna()
        .any(axis=1)
    )
    
    result_df = model.predict(df)
    #Predictions will not be flagged for empty scans here
    prediction_columns = [
        "predicted_material",
        "soil_probability",
        "non_soil_probability",
        "prediction_confidence"
    ]

    result_df.loc[~valid_scans, prediction_columns] = None

    result_df["valid_pxrf_scan"] = valid_scans
    
    output = io.StringIO()
    result_df.to_csv(output, index=False)
    output.seek(0)

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={
            "Content-Disposition":
            "attachment; filename=ArchaeoSight_Results.csv"
        })
#Request for the EBK file
@app.post("/ebk")
async def ebk(file: UploadFile = File(...)):

    contents = await file.read()

    df = pd.read_csv(
        io.BytesIO(contents)
    )

    #Check for these headers
    required_coords = {"X_Coord", "Y_Coord"}
    #If theyre missing
    missing = required_coords - set(df.columns)

    if missing:
        raise HTTPException(
            status_code=422,
            detail=("EBK requires spatial coordinates: "
                    + ", ".join(sorted(missing))))
    
    # The EBK process needs the classifier probability first
    result_df = model.predict(df)

    ebk_grid_df, original_points_df = dataframe_to_grid(
        result_df,
        x_col="X_Coord",
        y_col="Y_Coord",
        prob_col="non_soil_probability"
    )

    output = io.StringIO()

    ebk_grid_df.to_csv(
        output,
        index=False
    )

    output.seek(0)

    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={
            "Content-Disposition":
            "attachment; filename=ArchaeoSight_EBK_Grid.csv"
        }
    )
@app.get("/run")
def run_job(
    jobId: str,
    projectId: str
):
    return process_job(model, jobId, projectId, outputName)

#testing
@app.get("/test-convex")
def test_convex():
    result = client.query("testConnect:ping", {})
    return result
