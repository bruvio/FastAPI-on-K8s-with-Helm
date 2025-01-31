###########################
# S3 Buckets
###########################

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket that stores Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "avatars_bucket_name" {
  description = "Name of the S3 bucket used for storing avatars"
  value       = aws_s3_bucket.avatars.bucket
}

output "avatars_bucket_arn" {
  description = "ARN of the S3 bucket used for storing avatars"
  value       = aws_s3_bucket.avatars.arn
}


###########################
# DynamoDB Tables
###########################

output "terraform_lock_table_name" {
  description = "Name of the DynamoDB table used to lock Terraform state"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "terraform_lock_table_arn" {
  description = "ARN of the DynamoDB table used to lock Terraform state"
  value       = aws_dynamodb_table.terraform_lock.arn
}

output "users_table_name" {
  description = "Name of the DynamoDB table used for storing user data"
  value       = aws_dynamodb_table.users.name
}

output "users_table_arn" {
  description = "ARN of the DynamoDB table used for storing user data"
  value       = aws_dynamodb_table.users.arn
}


###########################
# IAM Resources
###########################

output "api_role_name" {
  description = "Name of the IAM role for the FastAPI application"
  value       = aws_iam_role.api_role.name
}

output "api_role_arn" {
  description = "ARN of the IAM role for the FastAPI application"
  value       = aws_iam_role.api_role.arn
}

output "api_policy_arn" {
  description = "ARN of the IAM policy attached to the FastAPI role"
  value       = aws_iam_policy.api_policy.arn
}

###########################
# K8S Resources
###########################
################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_arn : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority_data : null
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
}

output "cluster_id" {
  description = "The ID of the EKS cluster. Note: currently a value is returned only for local EKS clusters created on Outposts"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_id : null
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_oidc_issuer_url : null
}

output "cluster_dualstack_oidc_issuer_url" {
  description = "Dual-stack compatible URL on the EKS cluster for the OpenID Connect identity provider"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_dualstack_oidc_issuer_url : null
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_platform_version : null
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_status : null
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_primary_security_group_id : null
}

output "cluster_service_cidr" {
  description = "The CIDR block where Kubernetes pod and service IP addresses are assigned from"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_service_cidr : null
}

output "cluster_ip_family" {
  description = "The IP family used by the cluster (e.g. `ipv4` or `ipv6`)"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_ip_family : null
}

################################################################################
# Access Entry
################################################################################

output "access_entries" {
  description = "Map of access entries created and their attributes"
  value       = length(module.eks) > 0 ? module.eks[0].access_entries : null
}

################################################################################
# KMS Key
################################################################################

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = length(module.eks) > 0 ? module.eks[0].kms_key_arn : null
}

output "kms_key_id" {
  description = "The globally unique identifier for the key"
  value       = length(module.eks) > 0 ? module.eks[0].kms_key_id : null
}

output "kms_key_policy" {
  description = "The IAM resource policy set on the key"
  value       = length(module.eks) > 0 ? module.eks[0].kms_key_policy : null
}

################################################################################
# Security Group
################################################################################

output "cluster_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the cluster security group"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_security_group_arn : null
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_security_group_id : null
}

################################################################################
# Node Security Group
################################################################################

output "node_security_group_arn" {
  description = "Amazon Resource Name (ARN) of the node shared security group"
  value       = length(module.eks) > 0 ? module.eks[0].node_security_group_arn : null
}

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = length(module.eks) > 0 ? module.eks[0].node_security_group_id : null
}

################################################################################
# IRSA
################################################################################

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without leading `https://`)"
  value       = length(module.eks) > 0 ? module.eks[0].oidc_provider : null
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa = true`"
  value       = length(module.eks) > 0 ? module.eks[0].oidc_provider_arn : null
}

output "cluster_tls_certificate_sha1_fingerprint" {
  description = "The SHA1 fingerprint of the public key of the cluster's certificate"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_tls_certificate_sha1_fingerprint : null
}

################################################################################
# IAM Role
################################################################################

output "cluster_iam_role_name" {
  description = "Cluster IAM role name"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_iam_role_name : null
}

output "cluster_iam_role_arn" {
  description = "Cluster IAM role ARN"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_iam_role_arn : null
}

output "cluster_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_iam_role_unique_id : null
}

################################################################################
# EKS Auto Node IAM Role
################################################################################

output "node_iam_role_name" {
  description = "EKS Auto node IAM role name"
  value       = length(module.eks) > 0 ? module.eks[0].node_iam_role_name : null
}

output "node_iam_role_arn" {
  description = "EKS Auto node IAM role ARN"
  value       = length(module.eks) > 0 ? module.eks[0].node_iam_role_arn : null
}

output "node_iam_role_unique_id" {
  description = "Stable and unique string identifying the IAM role"
  value       = length(module.eks) > 0 ? module.eks[0].node_iam_role_unique_id : null
}

################################################################################
# EKS Addons
################################################################################

output "cluster_addons" {
  description = "Map of attribute maps for all EKS cluster addons enabled"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_addons : null
}

################################################################################
# EKS Identity Provider
################################################################################

output "cluster_identity_providers" {
  description = "Map of attribute maps for all EKS identity providers enabled"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_identity_providers : null
}

################################################################################
# CloudWatch Log Group
################################################################################

output "cloudwatch_log_group_name" {
  description = "Name of cloudwatch log group created"
  value       = length(module.eks) > 0 ? module.eks[0].cloudwatch_log_group_name : null
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = length(module.eks) > 0 ? module.eks[0].cloudwatch_log_group_arn : null
}

################################################################################
# Fargate Profile
################################################################################

output "fargate_profiles" {
  description = "Map of attribute maps for all EKS Fargate Profiles created"
  value       = length(module.eks) > 0 ? module.eks[0].fargate_profiles : null
}

################################################################################
# EKS Managed Node Group
################################################################################

output "eks_managed_node_groups" {
  description = "Map of attribute maps for all EKS managed node groups created"
  value       = length(module.eks) > 0 ? module.eks[0].eks_managed_node_groups : null
}

output "eks_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by EKS managed node groups"
  value       = length(module.eks) > 0 ? module.eks[0].eks_managed_node_groups_autoscaling_group_names : null
}

################################################################################
# Self Managed Node Group
################################################################################

output "self_managed_node_groups" {
  description = "Map of attribute maps for all self managed node groups created"
  value       = length(module.eks) > 0 ? module.eks[0].self_managed_node_groups : null
}

output "self_managed_node_groups_autoscaling_group_names" {
  description = "List of the autoscaling group names created by self-managed node groups"
  value       = length(module.eks) > 0 ? module.eks[0].self_managed_node_groups_autoscaling_group_names : null
}