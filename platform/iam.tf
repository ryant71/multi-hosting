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

  lifecycle {
    ignore_changes = [
      # Ignore if provider already exists
      url,
      client_id_list,
      thumbprint_list
    ]
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-multi-hosting-*",
          "arn:aws:s3:::terraform-state-multi-hosting-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups"
        ]
        Resource = [
          "arn:aws:dynamodb:eu-central-1:487196000447:table/terraform-locks-multi-hosting"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions",
          "cloudfront:GetOriginAccessControl"
        ]
        Resource = [
          "*"
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
          for zone_id in distinct([for site in var.websites : site.zone_id]) : "arn:aws:route53:::hostedzone/${zone_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:GetCertificate",
          "acm:ListTagsForCertificate"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:GetOpenIDConnectProvider",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "wafv2:GetWebACL",
          "wafv2:ListWebACLs",
          "wafv2:ListTagsForResource"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketWebsite",
          "s3:GetBucketPolicy",
          "s3:GetPublicAccessBlock",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketLogging",
          "s3:GetLifecycleConfiguration"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:ListInvalidations",
          "cloudfront:GetDistribution",
          "cloudfront:ListDistributions",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListTagsForResource"
        ]
        Resource = [
          "*"
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
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*"
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
          aws_cloudfront_distribution.distribution.arn
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
          for zone_id in distinct([for site in var.websites : site.zone_id]) : "arn:aws:route53:::hostedzone/${zone_id}"
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
          aws_acm_certificate.certificate.arn
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
