#!/bin/bash

# Test GitHub Actions OIDC role locally
# This script assumes the same role that GitHub Actions would use

set -e

# Use your AWS profile
export AWS_PROFILE=mine

# Configuration - update these values from your terraform outputs
ROLE_NAME="multi-site-content-github-actions"
AWS_ACCOUNT_ID="487196000447"
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

# GitHub Actions OIDC token simulation
# In real GHA, this comes from the GitHub Actions runtime
GITHUB_TOKEN_URL="https://token.actions.githubusercontent.com"
GITHUB_AUDIENCE="sts.amazonaws.com"

echo "=== Testing GitHub Actions OIDC Role Locally ==="
echo "Role ARN: $ROLE_ARN"
echo ""

# Check if we have admin credentials first
echo "1. Verifying current credentials..."
aws sts get-caller-identity

echo ""
echo "2. Assuming GitHub Actions OIDC role..."

# Assume the role (this simulates what GitHub Actions does)
TEMP_CREDS=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "LocalTestSession" \
  --duration-seconds 900)

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo "$TEMP_CREDS" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "$TEMP_CREDS" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "$TEMP_CREDS" | jq -r '.Credentials.SessionToken')

echo "3. Verifying assumed role credentials..."
aws sts get-caller-identity

echo ""
echo "4. Testing key permissions that were failing..."

# Test IAM policy access
echo "Testing IAM policy access..."
aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${ROLE_NAME}-policy" || echo "❌ IAM policy access failed"

# Test S3 state bucket access
echo "Testing S3 state bucket access..."
STATE_BUCKET=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'terraform-state-multi-hosting')].Name" --output text)
if [ ! -z "$STATE_BUCKET" ]; then
    echo "Found state bucket: $STATE_BUCKET"
    aws s3api get-bucket-policy --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-policy failed"
    aws s3api get-bucket-acl --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-acl failed"
    aws s3api get-bucket-cors --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-cors failed"
    aws s3api get-bucket-location --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-location failed"
    aws s3api get-bucket-website --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-website failed"
    aws s3api get-bucket-accelerate-configuration --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-accelerate-configuration failed"
    aws s3api get-bucket-request-payment --bucket "$STATE_BUCKET" || echo "❌ S3 get-bucket-request-payment failed"
else
    echo "❌ Could not find terraform state bucket"
fi

echo ""
echo "5. Running Terraform with assumed role..."

# Test terraform plan with the assumed role
echo "Running: terraform plan"
terraform plan || echo "❌ Terraform plan failed"

echo ""
echo "=== Test Complete ==="
echo "To clean up, unset the environment variables:"
echo "unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
