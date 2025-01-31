import pytest
from botocore.exceptions import ClientError
from unittest.mock import patch, MagicMock
import boto3


def test_user_integration(client):
    """
    Test the /users endpoint when there are no users.
    """
    resp = client.get("/users")
    assert resp.status_code == 200
    assert resp.json() == []


def test_s3_bucket_exists(client):
    """
    Test to ensure that 'bruvio-prima-sre' exists in the mocked S3 environment.
    """
    s3 = boto3.client("s3", region_name="eu-west-2")
    response = s3.list_buckets()
    bucket_names = [bucket["Name"] for bucket in response.get("Buckets", [])]
    assert "bruvio-prima-sre" in bucket_names, "S3 bucket 'bruvio-prima-sre' does not exist in the mock."


def test_create_user_success(client, tmp_path):
    """
    Test a successful /user POST.
    Verifies 201 is returned and avatar_url is in the response.
    """

    fake_avatar = tmp_path / "avatar.png"
    fake_avatar.write_bytes(b"fake image data")

    with fake_avatar.open("rb") as f:
        files = {"file": ("avatar.png", f, "image/png")}
        data = {"name": "John Doe", "email": "john@example.com"}

        response = client.post("/user", data=data, files=files)

    if response.status_code != 201:
        print("Response Status:", response.status_code)
        try:
            print("Response JSON:", response.json())
        except ValueError:
            print("Response Text:", response.text)
    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "John Doe"
    assert body["email"] == "john@example.com"

    assert body["avatar_url"].startswith("https://bruvio-prima-sre.s3.amazonaws.com/avatars/")

    s3 = boto3.client("s3", region_name="eu-west-2")
    s3_key = body["avatar_url"].split(f"https://bruvio-prima-sre.s3.amazonaws.com/")[1]
    try:
        s3.head_object(Bucket="bruvio-prima-sre", Key=s3_key)
        print(f"S3 object '{s3_key}' exists.")
    except ClientError as e:
        print(f"S3 object '{s3_key}' does not exist: {str(e)}")
        assert False, f"S3 object '{s3_key}' does not exist."
