from batch_jobs import get_prediction_params, load_data

project_id = "YOUR_PROJECT_ID"
job_id = "YOUR_JOB_ID"

params = get_prediction_params(job_id, project_id)

print("Received parameters:")
print(params.keys())

print("Assigned units:", len(params["unitMetadata"]))

df = load_data(params)

print("Total samples:", len(df))
print("Available columns:", list(df.columns))
