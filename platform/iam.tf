# IAM Configuration for GitHub Actions Deployment

# IAM Role for GitHub Actions (OIDC)
resource "aws_iam_role" "github_actions" {
  count = var.enable_oidc ? 1 : 0
  
  name = "${var.bucket_name}-github-actions"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github[0].arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })

  tags = {
    Project     = "multi-hosting"
    ManagedBy   = "terraform"
    Purpose     = "github-actions-deployment"
  }
}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_oidc ? 1 : 0
  
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = {
    Project     = "multi-hosting"
    ManagedBy   = "terraform"
    Purpose     = "github-actions-oidc"
  }
}

# IAM Policy for GitHub Actions Role
resource "aws_iam_policy" "github_actions" {
  count = var.enable_oidc ? 1 : 0
  
  name        = "${var.bucket_name}-github-actions-policy"
  description = "Policy for GitHub Actions deployment role"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketVersions"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions"
        ]
        Resource = [
          aws_cloudfront_distribution.main.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZones"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate"
        ]
        Resource = [
          aws_acm_certificate.main.arn
        ]
      }
    ]
  })

  tags = {
    Project     = "multi-hosting"
    ManagedBy   = "terraform"
    Purpose     = "github-actions-policy"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions" {
  count = var.enable_oidc ? 1 : 0
  
  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions[0].arn
}

# Traditional IAM User (fallback)
resource "aws_iam_user" "deployment" {
  count = var.create_iam_user ? 1 : 0
  
  name = "${var.bucket_name}-deployment"
  path = "/system/"

  tags = {
    Project     = "multi-hosting"
    ManagedBy   = "terraform"
    Purpose     = "deployment-user"
  }
}

# IAM Policy for deployment user
resource "aws_iam_policy" "deployment_user" {
  count = var.create_iam_user ? 1 : 0
  
  name        = "${var.bucket_name}-deployment-user-policy"
  description = "Policy for deployment user"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketVersions"
        ]
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions"
        ]
        Resource = [
          aws_cloudfront_distribution.main.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZones"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${var.hosted_zone_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate"
        ]
        Resource = [
          aws_acm_certificate.main.arn
        ]
      }
    ]
  })

  tags = {
    Project     = "multi-hosting"
    ManagedBy   = "terraform"
    Purpose     = "deployment-user-policy"
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "deployment_user" {
  count = var.create_iam_user ? 1 : 0
  
  user       = aws_iam_user.deployment[0].name
  policy_arn = aws_iam_policy.deployment_user[0].arn
}

# Access Key for deployment user
resource "aws_iam_access_key" "deployment" {
  count = var.create_iam_user ? 1 : 0
  
  user = aws_iam_user.deployment[0].name
}
