import os

from dotenv import load_dotenv
from pymongo import MongoClient


load_dotenv()


MONGODB_URI = os.getenv("MONGODB_URI")

if not MONGODB_URI:
    raise RuntimeError(
        "MONGODB_URI environment variable is missing"
    )


client = MongoClient(
    MONGODB_URI,
    serverSelectionTimeoutMS=5000,
)

database = client["flowvoice"]

users_collection = database["users"]
dictations_collection = database["dictations"]
notes_collection = database["notes"]
insights_collection = database["insights"]
dictionary_collection = database["dictionary"]


def check_database_connection():
    try:
        client.admin.command("ping")

        print(
            "Connected to MongoDB"
        )

        return True

    except Exception as exc:
        print(
            "MongoDB connection failed:",
            exc,
        )

        return False