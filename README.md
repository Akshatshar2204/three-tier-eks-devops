# Three-Tier MERN Application on AWS EKS

This project deploys a React frontend, Node.js backend, and MongoDB database on Amazon EKS.

## Architecture

- Frontend: React served by Nginx
- Backend: Node.js and Express REST API
- Database: MongoDB with persistent EBS storage
- Container registry: Amazon ECR
- Infrastructure as Code: Terraform
- Kubernetes packaging: Helm
- Planned automation and monitoring: Jenkins, Argo CD, Prometheus, and Grafana

## AWS Infrastructure

Terraform provisions a dedicated VPC, public and private subnets, routing, a NAT Gateway, an Amazon EKS cluster, managed worker nodes, and private ECR repositories.

The EBS CSI driver supports dynamically provisioned encrypted gp3 volumes for persistent database storage.

## Application Deployment

The Helm chart is located in `helm/three-tier-app/`.

It deploys:
- React frontend exposed through an AWS LoadBalancer
- Node.js backend exposed through an internal Kubernetes Service
- MongoDB with persistent storage and credentials supplied through a Kubernetes Secret

## Repository Structure

- `application-code/Application-Code/frontend/` — React frontend
- `application-code/Application-Code/backend/` — Node.js backend
- `helm/three-tier-app/` — Helm chart
- `infra/terraform/bootstrap/` — Terraform state-storage bootstrap
- `infra/terraform/eks/` — AWS networking, EKS, ECR, and storage configuration

## Source Application

The original starter code was provided by DevOps Institute Mumbai:

https://github.com/DevOpsInstituteMumbai-wq/End-to-End-Kubernetes-Three-Tier-DevSecOps-MERN-Stack-Project

## Security

Never commit Terraform state files, saved plans, AWS credentials, local `.tfvars` files, or real application secrets to Git.

## Project Status

The application has been deployed and tested on EKS. Jenkins CI/CD, Argo CD GitOps, and Prometheus/Grafana monitoring remain planned implementation steps.
