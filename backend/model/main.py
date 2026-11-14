from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import StreamingResponse
import pandas as pd
import io
import numpy as np

#testing import to prove Render Connection
from client_convex import client

from cloud_model import PXRFModel, FEATURE_COLUMNS
from ebk_predict import dataframe_to_grid
from batch_jobs import process_job
from batch_jobs import X_COORD, Y_COORD, COORD_COLUMNS

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
            detail="No recognized pXRF element columns"
        )

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
    required_coords = {X_COORD, Y_COORD}
    #If theyre missing
    missing = required_coords - set(df.columns)

    if missing:
        raise HTTPException(
            status_code=422,
            detail=("EBK requires spatial coordinates: "
                    + ", ".join(sorted(missing)))
        )

    # Identify available chemical elements
    available = [col for col in FEATURE_COLUMNS
                 if col in df.columns]

    if not available:
        raise HTTPException(
            status_code=422,
            detail="No recognized pXRF element columns"
        )

    #Identify scans with actual chemical measurements
    valid_scans = (
        df[available]
        .apply(pd.to_numeric, errors="coerce")
        .notna()
        .any(axis=1)
    )

    coords = (
        df[[X_COORD, Y_COORD]]
        .apply(pd.to_numeric, errors="coerce")
    )

    #Exclude invalid coordinates
    valid_coords = np.isfinite(
        coords.to_numpy(dtype=float)
    ).all(axis=1)

    valid_samples = valid_scans & valid_coords

    if not valid_samples.any():
        raise HTTPException(
            status_code=422,
            detail="No valid samples available for EBK"
        )

    #The EBK process needs the classifier probability first
    result_df = model.predict(df)

    location_data = result_df.loc[valid_samples].copy()

    location_data[[X_COORD, Y_COORD]] = coords.loc[
        valid_samples, 
        [X_COORD, Y_COORD]
    ]

    #Verify that enough distinct locations exist
    unique_points = location_data[[X_COORD, Y_COORD]
    ].drop_duplicates()

    if len(unique_points) < 10:
        raise HTTPException(
            status_code=422,
            detail="EBK requires at more than 10 distinct sample locations"
        )
        
    #Verify that coordinates can span a 2D region
    if (unique_points[X_COORD].nunique() < 2
        or unique_points[Y_COORD].nunique() < 2):
            raise HTTPException(
                status_code=422,
                detail="EBK requires variation in both coordinate axes"
            )

    try:
        ebk_grid_df, original_points_df = dataframe_to_grid(
            location_data,
            x_col=X_COORD,
            y_col=Y_COORD,
            prob_col="non_soil_probability"
        )
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(
            status_code=422,
            detail=f"EBK interpolation failed: {exc}"
        ) from exc


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
    projectId: str,
    outputName: str = "classification"
):
    return process_job(model, jobId, projectId, outputName)

#testing
@app.get("/test-convex")
def test_convex():
    result = client.query("health:ping", {})
    return {"message": result}
