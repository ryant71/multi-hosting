# Multi-Site Hosting Infrastructure

This Terraform configuration creates AWS infrastructure for hosting multiple static websites in a single S3 bucket with SSL certificates, CloudFront distribution, and Route53 DNS records.

## Architecture

**Single Infrastructure Stack:**
- 1 S3 bucket containing multiple subdirectories (one per website)
- 1 CloudFront distribution with multiple cache behaviors
- Multiple FQDNs pointing to the same CloudFront distribution
- 1 SSL certificate with multiple Subject Alternative Names (SAN) covering all domains

**S3 Bucket Structure:**
```
s3-bucket/
├── hiredgnu/
│   ├── index.html
│   └── assets/
├── example/
│   ├── index.html
│   └── assets/
└── blog/
    └── index.html
```

## Resources Created

- **SSL Certificate**: ACM certificate with DNS validation for multiple domains and wildcard subdomains
- **S3 Bucket**: Private S3 bucket for static website hosting
- **CloudFront Distribution**: CDN with WAF rate limiting, SSL certificate, and multiple cache behaviors
- **WAF Web ACL**: Rate limiting rule (500 requests per 5 minutes)
- **Route53 DNS**: A records for each FQDN pointing to CloudFront distribution

## Usage

1. Configure your AWS credentials
2. Create a `terraform.tfvars` file with your website configuration:

```hcl
bucket_name   = "my-multi-site-bucket"
hosted_zone_id = "Z1EXAMPLE123456"

websites = [
  {
    fqdn        = "hiredgnu.net"
    domain_name = "hiredgnu.net"
    path_prefix = "hiredgnu"
  },
  {
    fqdn        = "example.com"
    domain_name = "example.com"
    path_prefix = "example"
  }
]
```

3. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Variables

- `bucket_name`: The S3 bucket name (required)
- `hosted_zone_id`: The Route53 hosted zone ID (required)
- `websites`: List of websites to host (see example above)
  - `fqdn`: Fully qualified domain name for the website
  - `domain_name`: Base domain for SSL certificate
  - `path_prefix`: S3 path prefix for website files

## Outputs

- S3 bucket website URL and regional domain name
- CloudFront distribution domain name and ID
- SSL certificate ARN
- Lists of all website FQDNs and domains

## Website Deployment

Each website's static files should be uploaded to the corresponding S3 path:
- `hiredgnu.net` → `s3://bucket-name/hiredgnu/`
- `example.com` → `s3://bucket-name/example/`

## Notes

- The provider is configured for `us-east-1` as required by CloudFront for ACM certificates
- Backend configuration is commented out - uncomment and configure as needed
- All resources are tagged with project and management information
- Certificate covers both base domains and wildcard subdomains
- CloudFront cache behaviors route requests to appropriate S3 paths
