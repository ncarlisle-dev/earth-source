from fastapi import FastAPI, UploadFile, File
from fastapi.responses import StreamingResponse
import pandas as pd
import io

#testing import to prove Render Connection
from client_convex import client

from cloud_model import PXRFModel
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

    result_df = model.predict(df)

    ebk_grid_df, original_points_df = dataframe_to_grid(
        result_df,
        x_col="X_Coord",
        y_col="Y_Coord",
        prob_col="non_soil_probability")

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
