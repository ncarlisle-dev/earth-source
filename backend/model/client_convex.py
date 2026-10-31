import os
from pathlib import Path
from dotenv import load_dotenv
from convex import ConvexClient

load_dotenv(Path(__file__).resolve().parent / ".env")


def get_client_url(deploy_url):
  #establish approved urls instead of only one
  #The approved URLs can be added in the .env file
  approved_urls = {
    url.strip().rstrip("/")
    for url in os.environ.get("ALLOWED_CONVEX_URLS", "").split(",")
      if url.strip()
  }

  deploy_url = deploy_url.rstrip('/')

  if deploy_url not in approved_urls:
        raise ValueError("This is not an approved Convex deployment")

  return ConvexClient(deploy_url)

#SAVE SINGLE CLIENT CODE RETURN FOR TESTING
#Read the values from env file
#Create the Client Connection
client = get_client_url(os.environ["CONVEX_URL"])
