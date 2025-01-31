

terraform {
  backend "s3" {
    key     = "prima-sre/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # version = "~> 5.83.0"
    }
  }

}


locals {
  contact = "bruno.viola@pm.me"
  project = var.project
  common_tags = {
    Environment = terraform.workspace
    Project     = local.project
    Owner       = local.contact
    ManagedBy   = "Terraform"
  }


}


data "aws_caller_identity" "current" {}









