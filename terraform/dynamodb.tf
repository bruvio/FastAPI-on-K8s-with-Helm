
#########################################
# DYNAMODB TABLES
#########################################

# Table for Terraform state locking
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.terraform_lock_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"

  }
  tags = local.common_tags
}

# Table for user data 
resource "aws_dynamodb_table" "users" {
  name         = var.users_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"

  attribute {
    name = "email"
    type = "S"
  }
  tags = local.common_tags
}


