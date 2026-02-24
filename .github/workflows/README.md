# GitHub Actions Workflows

This directory contains the GitHub Actions workflows for automated deployment and CI/CD of the multi-site hosting infrastructure.

## Workflows Overview

### 1. `ci.yml` - Continuous Integration
- **Triggers**: Push to main/develop, pull requests
- **Purpose**: Run tests, linting, and security scans
- **Jobs**:
  - Lint Terraform infrastructure
  - Validate site structures
  - Test Pelican builds
  - Security vulnerability scanning
  - Link validation

### 2. `deploy-infrastructure.yml` - Infrastructure Deployment
- **Triggers**: Push to platform/, manual dispatch
- **Purpose**: Deploy/update AWS infrastructure
- **Features**:
  - Terraform plan/apply
  - State management
  - Output sharing with other workflows
  - PR previews with plan summaries

### 3. `deploy-crowded-spot.yml` - Static Site Deployment
- **Triggers**: Push to sites/crowded.spot/, manual dispatch
- **Purpose**: Deploy simple static site
- **Features**:
  - Direct S3 sync
  - CloudFront cache invalidation
  - Deployment verification
  - PR previews

### 4. `deploy-hiredgnu-net.yml` - Pelican Site Deployment
- **Triggers**: Push to sites/hiredgnu.net/, manual dispatch
- **Purpose**: Build and deploy Pelican-generated site
- **Features**:
  - Python environment setup
  - Pelican build process
  - HTML optimization
  - S3 sync with cache headers
  - CloudFront invalidation

### 5. `deploy-all.yml` - Full Deployment
- **Triggers**: Push affecting multiple components, manual dispatch
- **Purpose**: Deploy infrastructure and all sites
- **Features**:
  - Orchestrate all deployments
  - Conditional deployment based on changes
  - Job dependencies and outputs
  - Comprehensive deployment summary

## Required GitHub Secrets (OIDC)

### **OIDC Configuration**
- `AWS_ROLE_ARN` - The IAM role ARN created by Terraform

### **Repository Variables** (Non-sensitive)
- `TF_VAR_BUCKET_NAME` - S3 bucket name for infrastructure
- `TF_VAR_HOSTED_ZONE_ID` - Route53 hosted zone ID
- `S3_BUCKET_NAME` - Fallback S3 bucket name
- `CLOUDFRONT_DISTRIBUTION_ID` - Fallback CloudFront distribution ID

### **Optional (Fallback)**
- `AWS_ACCESS_KEY_ID` - AWS access key (if OIDC disabled)
- `AWS_SECRET_ACCESS_KEY` - AWS secret key (if OIDC disabled)

## Workflow Features

### Path-Based Triggers
Workflows only run when relevant files change:
- Infrastructure changes → `platform/` files
- Site changes → `sites/*/` files
- Full deployment → any changes

### Manual Dispatch
All deployment workflows support manual triggering with:
- Environment selection (dev/prod)
- Conditional deployment options

### Security & Validation
- Terraform security scanning with tfsec
- Vulnerability scanning with Trivy
- HTML validation
- Link checking
- Structure validation

### Deployment Verification
- S3 file existence checks
- CloudFront invalidation completion
- Build output validation
- Error handling and rollback considerations

## Usage Examples

### Deploy Infrastructure Only
```bash
# Push to platform/ directory
git add platform/
git commit -m "Update infrastructure"
git push main
```

### Deploy Single Site
```bash
# Push to specific site directory
git add sites/crowded.spot/
git commit -m "Update crowded.spot"
git push main
```

### Manual Full Deployment
1. Go to Actions tab in GitHub
2. Select "Deploy All Sites" workflow
3. Click "Run workflow"
4. Choose options and run

### Preview Changes
Create a pull request to see:
- Infrastructure plan changes
- Site file previews
- Build validation
- Security scan results

## Workflow Dependencies

```
deploy-all.yml
├── infrastructure (job)
│   └── outputs → s3_bucket, cloudfront_distribution
├── deploy-crowded-spot (depends on infrastructure)
└── deploy-hiredgnu-net (depends on infrastructure)
```

## Monitoring and Troubleshooting

### Workflow Logs
- Check Actions tab in GitHub
- Review individual job logs
- Monitor artifact uploads

### Common Issues
- **AWS credentials**: Verify secrets are correctly configured
- **Terraform state**: Check for state locking issues
- **Build failures**: Review site structure and dependencies
- **S3 permissions**: Ensure IAM roles have correct permissions

### Artifacts
- Terraform plans (30-day retention)
- Build outputs for debugging
- Security scan results (SARIF format)

## Best Practices

1. **Branch Protection**: Require PR reviews for main branch
2. **Environment Separation**: Use different AWS accounts/accounts for dev/prod
3. **Secret Management**: Rotate AWS credentials regularly
4. **Monitoring**: Set up alerts for workflow failures
5. **Documentation**: Keep workflow documentation updated

## Migration from CircleCI

If migrating from CircleCI:

### Similarities
- YAML-based configuration
- Job dependencies and workflows
- Secret management
- Artifact handling

### Differences
- **Triggers**: GitHub Actions uses different event syntax
- **Context**: GitHub Actions uses environments/secrets differently
- **Marketplace**: More extensive action ecosystem
- **Pricing**: Different free tier and usage limits

### Migration Steps
1. Convert CircleCI config to GitHub Actions syntax
2. Update trigger patterns
3. Migrate secrets to GitHub repository settings
4. Test workflows in development branch
5. Update CI/CD documentation
6. Decommission CircleCI configuration

## Performance Optimization

- **Parallel Jobs**: Run independent jobs in parallel
- **Caching**: Cache dependencies (Python, Terraform)
- **Conditional Execution**: Skip unnecessary jobs
- **Artifact Retention**: Configure appropriate retention policies
