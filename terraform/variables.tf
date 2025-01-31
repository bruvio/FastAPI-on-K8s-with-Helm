
# 
variable "terraform_state_bucket_name" {
  description = "Bucket for storing the Terraform *.tfstate files."
  type        = string
  default     = "some-random-name-bruvio-1234-prima"
}

# 
variable "terraform_lock_table_name" {
  description = "DynamoDB table used to lock Terraform state."
  type        = string
  default     = "some-random-name-bruvio-1234-prima-terraform-lock-table"
}

# 
variable "users_table_name" {
  description = "DynamoDB table for the challenge users data."
  type        = string
  default     = "Users"
}

# 
variable "avatars_bucket_name" {
  description = "S3 bucket for storing avatars (required by the Python API)"
  type        = string
  default     = "my-api-avatars"
}


variable "project" {
  description = "name of project"
  type        = string
  default     = "prima-sre"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "create_cluster" {
  type        = bool
  description = "enable provisioning of EKS cluster and VPC"
  default     = false
}

variable "cluster_name" {
  description = "name of the EKS cluster"
  default     = "lallero"
  type        = string
}