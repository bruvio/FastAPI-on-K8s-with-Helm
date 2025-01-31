#########################################
# IAM RESOURCES (Role + Policy + Attachment)
#########################################

# 1) IAM Role for the application
resource "aws_iam_role" "api_role" {
  name               = "my-api-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = local.common_tags
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "eks.amazonaws.com"

      ]
    }
  }
}

# 2) IAM Policy to grant read/write to DDB table + S3
data "aws_iam_policy_document" "api_policy_doc" {
  # Access to the Users DynamoDB table
  statement {
    sid = "DynamoDBUsersAccess"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.users.arn]
  }

  # Access to the S3 bucket (avatars)
  statement {
    sid = "S3AvatarsAccess"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.avatars.arn,
      "${aws_s3_bucket.avatars.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "api_policy" {
  name   = "my-api-iam-policy"
  policy = data.aws_iam_policy_document.api_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "api_role_attachment" {
  role       = aws_iam_role.api_role.name
  policy_arn = aws_iam_policy.api_policy.arn
}
