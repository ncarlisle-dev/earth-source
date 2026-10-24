from client_convex import get_convex_client

def run_job(job_id, project_id, deploy_url):
  client = get_client_url(deploy_url)

  arguments = {"jobId": job_id,"projectId": project_id}

  #Review Convex Schema for function names
