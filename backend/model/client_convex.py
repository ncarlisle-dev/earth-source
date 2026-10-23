import os
from pathlib import Path
from dotenv import load_dotenv
from convex import ConvexClient

#Read the values from env file

load_dotenv()

#Retrieve the Convex URL
convex_url = os.environ["URL HERE"]

#Create the Client Connection
client = ConvexClient(convex_url)
