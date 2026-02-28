# IAM Configuration for GitHub Actions Deployment

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
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "github-actions-oidc"
  }

  lifecycle {
    ignore_changes = [
      url,
      client_id_list,
      thumbprint_list,
    ]
  }
}

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
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::487196000447:user/ryant"
        }
      }
    ]
  })

  tags = {
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "github-actions-deployment"
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
      # -----------------------------------------------------------------------
      # S3 — deployment bucket (object-level operations)
      # -----------------------------------------------------------------------
      {
        Sid    = "S3DeploymentBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:GetObjectAcl",
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*",
        ]
      },
      # -----------------------------------------------------------------------
      # S3 — deployment bucket (bucket-level operations)
      # -----------------------------------------------------------------------
      {
        Sid    = "S3DeploymentBucketLevel"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucketWebsite",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketTagging",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:PutBucketPublicAccessBlock",
        ]
        Resource = [
          aws_s3_bucket.bucket.arn,
        ]
      },
      # -----------------------------------------------------------------------
      # S3 — Terraform state bucket
      # -----------------------------------------------------------------------
      {
        Sid    = "S3TerraformState"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:CreateBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPolicy",
          "s3:GetBucketAcl",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketLogging",
          "s3:GetBucketTagging",
          "s3:GetBucketWebsite",
          "s3:GetEncryptionConfiguration",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetBucketPublicAccessBlock",
        ]
        Resource = [
          "*",
          "arn:aws:s3:::terraform-state-multi-hosting-*",
          "arn:aws:s3:::terraform-state-multi-hosting-*/*",
        ]
      },
      # -----------------------------------------------------------------------
      # DynamoDB — Terraform state locking
      # -----------------------------------------------------------------------
      {
        Sid    = "DynamoDBTerraformLocks"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:ListTagsOfResource",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ]
        Resource = [
          "arn:aws:dynamodb:eu-central-1:487196000447:table/terraform-locks-multi-hosting",
        ]
      },
      # -----------------------------------------------------------------------
      # CloudFront
      # -----------------------------------------------------------------------
      {
        Sid    = "CloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetInvalidation",
          "cloudfront:GetOriginAccessControl",
          "cloudfront:ListDistributions",
          "cloudfront:ListInvalidations",
          "cloudfront:ListTagsForResource",
        ]
        Resource = ["*"]
      },
      # -----------------------------------------------------------------------
      # Route 53
      # -----------------------------------------------------------------------
      {
        Sid    = "Route53"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
        ]
        Resource = [
          for zone_id in distinct([for site in var.websites : site.zone_id]) :
          "arn:aws:route53:::hostedzone/${zone_id}"
        ]
      },
      # -----------------------------------------------------------------------
      # ACM
      # -----------------------------------------------------------------------
      {
        Sid    = "ACM"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
        ]
        Resource = ["*"]
      },
      # -----------------------------------------------------------------------
      # IAM — scoped to roles managed by this project
      # -----------------------------------------------------------------------
      {
        Sid    = "IAMSelfManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:GetOpenIDConnectProvider",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:UpdateRole",
          "iam:UpdateRoleDescription",
        ]
        Resource = [
          "arn:aws:iam::487196000447:role/${var.bucket_name}-*",
          "arn:aws:iam::487196000447:policy/${var.bucket_name}-*",
          "arn:aws:iam::487196000447:oidc-provider/token.actions.githubusercontent.com",
        ]
      },
      # -----------------------------------------------------------------------
      # WAFv2 (read-only)
      # -----------------------------------------------------------------------
      {
        Sid    = "WAFv2ReadOnly"
        Effect = "Allow"
        Action = [
          "wafv2:GetWebACL",
          "wafv2:ListTagsForResource",
          "wafv2:ListWebACLs",
        ]
        Resource = ["*"]
      },
    ]
  })

  tags = {
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "github-actions-policy"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "github_actions" {
  count = var.enable_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions[0].arn
}

# ------------------------------------------------------------------------------
# Traditional IAM User (fallback / non-OIDC environments)
# ------------------------------------------------------------------------------

resource "aws_iam_user" "deployment" {
  count = var.create_iam_user ? 1 : 0

  name = "${var.bucket_name}-deployment"
  path = "/system/"

  tags = {
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "deployment-user"
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
      # -----------------------------------------------------------------------
      # S3 — deployment bucket (object-level operations)
      # -----------------------------------------------------------------------
      {
        Sid    = "S3DeploymentBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}/*",
        ]
      },
      # -----------------------------------------------------------------------
      # S3 — deployment bucket (bucket-level operations)
      # -----------------------------------------------------------------------
      {
        Sid    = "S3DeploymentBucketLevel"
        Effect = "Allow"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucketWebsite",
          "s3:PutBucketPublicAccessBlock",
        ]
        Resource = [
          aws_s3_bucket.bucket.arn,
        ]
      },
      # -----------------------------------------------------------------------
      # CloudFront
      # -----------------------------------------------------------------------
      {
        Sid    = "CloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetInvalidation",
          "cloudfront:ListDistributions",
          "cloudfront:ListInvalidations",
        ]
        Resource = [
          aws_cloudfront_distribution.distribution.arn,
        ]
      },
      # -----------------------------------------------------------------------
      # Route 53
      # -----------------------------------------------------------------------
      {
        Sid    = "Route53"
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
        ]
        Resource = [
          for zone_id in distinct([for site in var.websites : site.zone_id]) :
          "arn:aws:route53:::hostedzone/${zone_id}"
        ]
      },
      # -----------------------------------------------------------------------
      # ACM
      # -----------------------------------------------------------------------
      {
        Sid    = "ACM"
        Effect = "Allow"
        Action = [
          "acm:DescribeCertificate",
          "acm:GetCertificate",
          "acm:ListCertificates",
        ]
        Resource = [
          aws_acm_certificate.certificate.arn,
        ]
      },
    ]
  })

  tags = {
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "deployment-user-policy"
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "deployment_user" {
  count = var.create_iam_user ? 1 : 0

  user       = aws_iam_user.deployment[0].name
  policy_arn = aws_iam_policy.deployment_user[0].arn
}

# Access key for deployment user
resource "aws_iam_access_key" "deployment" {
  count = var.create_iam_user ? 1 : 0

  user = aws_iam_user.deployment[0].name
}
