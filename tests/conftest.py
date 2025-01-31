import pytest
from moto import mock_dynamodb, mock_s3
from fastapi.testclient import TestClient
from prima_sre.app import app
import boto3
import os
import logging


logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
logging.getLogger("boto3").setLevel(logging.WARNING)
logging.getLogger("botocore").setLevel(logging.WARNING)
logging.getLogger("urllib3").setLevel(logging.WARNING)
logging.getLogger("fastapi").setLevel(logging.INFO)
logging.getLogger("starlette").setLevel(logging.WARNING)
logging.getLogger("s3transfer").setLevel(logging.WARNING)
logging.getLogger("python_multipart").setLevel(logging.WARNING)
logging.getLogger("asyncio").setLevel(logging.WARNING)


@pytest.fixture()
def aws_mocks(monkeypatch):
    """
    Pytest fixture to mock AWS S3 and DynamoDB services using Moto.
    Sets environment variables, creates a mock S3 bucket and DynamoDB table,
    and imports the FastAPI app after setting up the mocks.
    """

    monkeypatch.setenv("AWS_REGION", "eu-west-2")
    monkeypatch.setenv("DYNAMO_TABLE", "Users")
    monkeypatch.setenv("S3_BUCKET", "bruvio-prima-sre")

    with mock_s3(), mock_dynamodb():

        s3 = boto3.client("s3", region_name="eu-west-2")
        logger.info("Creating S3 bucket 'bruvio-prima-sre'...")
        s3.create_bucket(Bucket="bruvio-prima-sre", CreateBucketConfiguration={"LocationConstraint": "eu-west-2"})
        logger.info("S3 bucket 'bruvio-prima-sre' created successfully.")

        response = s3.list_buckets()
        bucket_names = [bucket["Name"] for bucket in response.get("Buckets", [])]
        assert "bruvio-prima-sre" in bucket_names, "S3 bucket 'bruvio-prima-sre' was not created."

        dynamo = boto3.client("dynamodb", region_name="eu-west-2")
        logger.info("Creating DynamoDB table 'Users'...")
        dynamo.create_table(
            TableName="Users",
            KeySchema=[{"AttributeName": "name", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "name", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        logger.info("DynamoDB table 'Users' created successfully.")

        response = dynamo.list_tables()
        assert "Users" in response.get("TableNames", []), "DynamoDB table 'Users' was not created."

        from prima_sre.app import app

        yield app


@pytest.fixture
def client(aws_mocks):
    """
    Pytest fixture to provide a TestClient for the FastAPI app.
    """
    with TestClient(aws_mocks) as test_client:
        yield test_client
