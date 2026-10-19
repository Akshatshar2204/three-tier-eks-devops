output "frontend_ecr_url" {
  description = "Private ECR repository URL for the React frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_url" {
  description = "Private ECR repository URL for the Node.js backend"
  value       = aws_ecr_repository.backend.repository_url
}
