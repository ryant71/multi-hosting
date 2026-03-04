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

echo "Setup complete! Use this role ARN in GitHub secrets:"
echo "$ROLE_ARN"
