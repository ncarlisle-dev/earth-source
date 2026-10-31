from batch_jobs import get_prediction_params, load_data

project_id = "jn77p7f5r5r26agmf9f765a1k98gz3bq"
job_id = "jd7fcpxj4mfea0gf5raxqkqmmn8gy0jb"

params = get_prediction_params(job_id, project_id)

print("Received parameters:")
print(params.keys())

print("Assigned units:", len(params["unitMetadata"]))

df = load_data(params)

print("Total samples:", len(df))
print("Available columns:", list(df.columns))
