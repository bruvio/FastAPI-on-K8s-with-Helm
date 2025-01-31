# app/app.py

import os
import uuid
import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
import logging

app = FastAPI(
    title="Prima SRE",
    description="does some stuff and prove something (or not!)",
    version="0.0.1",
    contact={
        "name": "bruvo",
        "slack": "#bruvio-support",
        "email": "bruno.viola@pm.me",
    },
)


logger = logging.getLogger("app_logger")
logger.setLevel(logging.INFO)


if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    handler.setFormatter(formatter)
    logger.addHandler(handler)


AWS_REGION = os.getenv("AWS_REGION", "eu-west-2")
DYNAMO_TABLE = os.getenv("DYNAMO_TABLE", "Users")
S3_BUCKET = os.getenv("S3_BUCKET", "bruvio-prima-sre")


def get_dynamo_client():
    """
    Initialize and return a DynamoDB client.
    """
    return boto3.client("dynamodb", region_name=AWS_REGION)


def get_s3_client():
    """
    Initialize and return an S3 client.
    """
    return boto3.client("s3", region_name=AWS_REGION)


@app.get("/")
def root():  # pragma: no cover
    """
    landing page
    """
    logger.info("bruvio")
    return {"status": "ok"}


@app.get("/health")
def health_check():  # pragma: no cover
    """
    Simple health endpoint (for readiness/liveness probes).
    """
    logger.info("Health check endpoint called.")
    return {"status": "ok"}


@app.get("/users")
def get_users():
    """
    Fetch all user items from DynamoDB, handling pagination.
    Returns:
      200: JSON list of user objects
    """
    dynamo_client = get_dynamo_client()
    users = []

    try:

        paginator = dynamo_client.get_paginator("scan")
        page_iterator = paginator.paginate(TableName=DYNAMO_TABLE)

        for page in page_iterator:
            items = page.get("Items", [])
            for item in items:
                user = {
                    "name": item.get("name", {}).get("S", ""),
                    "email": item.get("email", {}).get("S", ""),
                    "avatar_url": item.get("avatar_url", {}).get("S", ""),
                }
                users.append(user)

        logger.info(f"Retrieved {len(users)} users from DynamoDB.")

    except ClientError as e:  # pragma: no cover
        logger.error(f"DynamoDB scan failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to retrieve users from the database.")

    return users


@app.post("/user")
def create_user(name: str = Form(...), email: str = Form(...), file: UploadFile = File(...)):
    """
    Create a new user and upload avatar to S3.
    Form fields:
      name (str) - user's name
      email (str) - user's email
      file (UploadFile) - user's avatar image
    """
    s3_client = get_s3_client()
    dynamo_client = get_dynamo_client()

    logger.info(f"Using S3_BUCKET: {S3_BUCKET}")

    file_extension = file.filename.split(".")[-1] if "." in file.filename else "png"
    s3_key = f"avatars/{uuid.uuid4()}.{file_extension}"
    logger.debug(f"Generated S3 key: {s3_key}")

    try:
        logger.info("Uploading file to S3...")
        s3_client.upload_fileobj(file.file, S3_BUCKET, s3_key)
        logger.info("File uploaded to S3 successfully.")
    except ClientError as e:  # pragma: no cover
        logger.error(f"S3 upload failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to upload avatar: {str(e)}")

    avatar_url = f"https://{S3_BUCKET}.s3.amazonaws.com/{s3_key}"
    logger.info(f"Avatar URL: {avatar_url}")

    try:
        logger.info("Storing user in DynamoDB...")
        dynamo_client.put_item(
            TableName=DYNAMO_TABLE, Item={"name": {"S": name}, "email": {"S": email}, "avatar_url": {"S": avatar_url}}
        )
        logger.info("User stored in DynamoDB successfully.")
    except ClientError as e:  # pragma: no cover
        logger.error(f"DynamoDB put_item failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to save user: {str(e)}")

    return JSONResponse(status_code=201, content={"name": name, "email": email, "avatar_url": avatar_url})
