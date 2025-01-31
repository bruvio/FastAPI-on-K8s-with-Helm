#########################################
# S3 BUCKETS
#########################################

# 1) Bucket that will physically store Terraform state files
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform_state_bucket_name

  # Enable versioning for state backups
  versioning {
    enabled = true
  }

  # Basic server-side encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = local.common_tags
}

# 2) Bucket for user avatars (used by the FastAPI service)
resource "aws_s3_bucket" "avatars" {
  bucket = var.avatars_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = local.common_tags
}

