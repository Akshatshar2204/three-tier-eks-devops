output "vpc_id" {
  description = "VPC created for the assignment"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "node_group_name" {
  description = "Managed worker node group name"
  value       = aws_eks_node_group.workers.node_group_name
}

output "configure_kubectl_command" {
  description = "Command for configuring kubectl"
  value       = "aws eks update-kubeconfig --region ap-south-1 --name ${aws_eks_cluster.main.name}"
}
