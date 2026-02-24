#!/bin/bash

# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the IAM role for GitHub Actions
aws iam create-role --role-name multi-hosting-ahx6m-github-actions --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::'$AWS_ACCOUNT_ID':oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:ryant71/multi-hosting:*"
        }
      }
    }
  ]
}'

# Get the role ARN
ROLE_ARN=$(aws iam get-role --role-name multi-hosting-ahx6m-github-actions --query Role.Arn --output text)
echo "Role ARN: $ROLE_ARN"

# Create OIDC provider if it doesn't exist
aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 2>/dev/null || echo "OIDC provider already exists"

echo "Setup complete! Use this role ARN in GitHub secrets:"
echo "$ROLE_ARN"
