#!/bin/bash
# Run this after 'terraform apply' to sync GitHub Actions secrets from Terraform outputs.
# Requires: AWS credentials active (export AWS_PROFILE=mine), gh CLI authenticated.

set -euo pipefail

ROLE_ARN=$(terraform output -raw github_actions_role_arn)
STATE_BUCKET=$(terraform output -raw terraform_state_bucket)

echo "Role ARN:     $ROLE_ARN"
echo "State bucket: $STATE_BUCKET"

gh secret set AWS_ROLE_ARN --body "$ROLE_ARN"
gh secret set TF_STATE_BUCKET --body "$STATE_BUCKET"

echo "GitHub secrets updated."
