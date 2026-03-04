output "s3_bucket_website_url" {
  description = "URL for website hosted on S3"
  value       = aws_s3_bucket_website_configuration.bucket.website_endpoint
}

output "s3_bucket_regional_domain_name" {
  description = "Regional domain name for bucket"
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "cloudfront_distribution_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = aws_cloudfront_distribution.distribution.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.distribution.id
}

output "s3_content_bucket_name" {
  description = "S3 Bucket Name for site content"
  value       = aws_s3_bucket.bucket.id
}

output "certificate_arn" {
  description = "SSL certificate ARN"
  value       = aws_acm_certificate.certificate.arn
}

output "website_fqdns" {
  description = "List of website FQDNs"
  value       = [for site in var.websites : site.fqdn]
}

output "website_domains" {
  description = "List of website domains"
  value       = [for site in var.websites : site.domain_name]
}

output "terraform_state_bucket" {
  description = "Terraform state S3 bucket name"
  value       = aws_s3_bucket.terraform_state.id
}

# IAM Outputs
output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = var.enable_oidc ? aws_iam_role.github_actions[0].arn : null
}

output "github_actions_role_name" {
  description = "GitHub Actions IAM role name"
  value       = var.enable_oidc ? aws_iam_role.github_actions[0].name : null
}

output "deployment_user_name" {
  description = "Deployment IAM user name"
  value       = var.create_iam_user ? aws_iam_user.deployment[0].name : null
}

output "deployment_access_key_id" {
  description = "Deployment IAM user access key ID"
  value       = var.create_iam_user ? aws_iam_access_key.deployment[0].id : null
  sensitive   = true
}

output "deployment_access_key_secret" {
  description = "Deployment IAM user access key secret"
  value       = var.create_iam_user ? aws_iam_access_key.deployment[0].secret : null
  sensitive   = true
}
