# IAM role trusted by EKS Pod Identity
resource "aws_iam_role" "jenkins_ecr" {
  name = "${var.project_name}-jenkins-ecr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

# Policy that allows Jenkins to authenticate and push to the two project repositories
resource "aws_iam_policy" "jenkins_ecr_push" {
  name        = "${var.project_name}-jenkins-ecr-push"
  description = "Allow Jenkins agents to push images to the project's ECR repositories"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "PushProjectImages"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
        Resource = [
          aws_ecr_repository.frontend.arn,
          aws_ecr_repository.backend.arn
        ]
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr_push" {
  role       = aws_iam_role.jenkins_ecr.name
  policy_arn = aws_iam_policy.jenkins_ecr_push.arn
}

# Associate the IAM role with Jenkins build-agent pods
resource "aws_eks_pod_identity_association" "jenkins_ecr" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "jenkins"
  service_account = "jenkins-agent"
  role_arn        = aws_iam_role.jenkins_ecr.arn

  depends_on = [
    aws_iam_role_policy_attachment.jenkins_ecr_push
  ]

  tags = local.common_tags
}
