# Example terraform.tfvars file
# Copy this to terraform.tfvars and fill in your values

# S3 Bucket Configuration
bucket_name = "multi-site-content"

# GitHub Actions OIDC Configuration (Recommended)
enable_oidc       = true
github_repository = "ryant71/multi-hosting"

# Traditional IAM User (Fallback - not recommended for production)
create_iam_user = false

websites = [
  {
    fqdn        = "hiredgnu.net"
    domain_name = "hiredgnu.net"
    path_prefix = "hiredgnu.net"   # Include .net for consistency
    zone_id     = "Z2B00DRLLVN6P9" # Route53 hosted zone ID for hiredgnu.net
  },
  {
    fqdn        = "crowded.spot"
    domain_name = "crowded.spot"
    path_prefix = "crowded.spot"
    zone_id     = "Z07783278IYDDVTZ4SXP" # Route53 hosted zone ID for crowded.spot
  }
]