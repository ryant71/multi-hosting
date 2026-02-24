variable "bucket_name" {
  description = "The name of the S3 Bucket"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route53 hosted zone ID"
  type        = string
}

variable "websites" {
  description = "List of websites to host"
  type = list(object({
    fqdn        = string
    domain_name = string
    path_prefix = string
    zone_id     = string  # Added: Route53 hosted zone ID for each domain
  }))
  default = [
    {
      fqdn        = "hiredgnu.net"
      domain_name = "hiredgnu.net"
      path_prefix = "hiredgnu"
      zone_id     = ""  # Must be specified
    }
  ]
}

variable "enable_oidc" {
  description = "Enable GitHub Actions OIDC integration"
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository name (format: owner/repo)"
  type        = string
  default     = "ryant71/multi-hosting"
}

variable "create_iam_user" {
  description = "Create traditional IAM user with access keys"
  type        = bool
  default     = false
}
