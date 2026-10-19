variable "project_name" {
  description = "Name prefix for project resources"
  type        = string
  default     = "three-tier-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.37"
}

variable "vpc_cidr" {
  description = "CIDR range for the project VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR ranges"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR ranges"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Public IPv4 CIDRs permitted to reach the Kubernetes API"
  type        = list(string)

  validation {
    condition = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "Provide at least one valid CIDR, preferably your current public IPv4 address with /32."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "node_capacity_type" {
  description = "Worker node purchasing option"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "Use SPOT or ON_DEMAND."
  }
}

variable "node_min_size" {
  type        = number
  description = "Minimum worker nodes"
  default     = 1
}

variable "node_desired_size" {
  type        = number
  description = "Initial desired worker nodes"
  default     = 2
}

variable "node_max_size" {
  type        = number
  description = "Maximum worker nodes"
  default     = 3
}
