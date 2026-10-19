output "state_bucket_name" {
  description = "S3 bucket used for the three-tier EKS project Terraform state"
  value       = aws_s3_bucket.tf_state.bucket
}

output "state_bucket_region" {
  description = "AWS region containing the state bucket"
  value       = var.aws_region
}
