terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "three-tier-eks-tfstate-828479100787-4f3432b6"
    key          = "three-tier-eks/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = ["828479100787"]
}

variable "aws_region" {
  description = "AWS region for the three-tier EKS project"
  type        = string
  default     = "ap-south-1"
}
