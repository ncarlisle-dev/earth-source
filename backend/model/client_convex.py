import os
from pathlib import Path
from dotenv import load_dotenv
from convex import ConvexClient

#Read the values from env file

load_dotenv(Path(__file__).resolve().parent / ".env")

#Retrieve the Convex URL
convex_url = os.environ["CONVEX_URL"]

#Create the Client Connection
client = ConvexClient(convex_url)
