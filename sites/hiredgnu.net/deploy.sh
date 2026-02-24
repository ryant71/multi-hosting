#!/bin/bash

# Deploy script for hiredgnu.net Pelican site
# This script builds the Pelican site and deploys to S3

set -e

# Configuration
SITE_NAME="hiredgnu.net"
S3_BUCKET=""  # Will be set from terraform output or environment variable
DISTRIBUTION_ID=""  # Will be set from terraform output or environment variable
SRC_DIR="src"
OUTPUT_DIR="output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting deployment for ${SITE_NAME}${NC}"

# Check if we're in the right directory
if [ ! -d "$SRC_DIR" ]; then
    echo -e "${RED}Error: src directory not found. Please run this script from the hiredgnu.net directory${NC}"
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed or not in PATH${NC}"
    exit 1
fi

# Get S3 bucket and distribution ID from terraform outputs if not set
if [ -z "$S3_BUCKET" ] && [ -f "../../platform/terraform.tfstate" ]; then
    echo -e "${YELLOW}Getting S3 bucket from Terraform outputs...${NC}"
    S3_BUCKET=$(cd ../../platform && terraform output -raw s3_bucket_name 2>/dev/null || echo "")
fi

if [ -z "$DISTRIBUTION_ID" ] && [ -f "../../platform/terraform.tfstate" ]; then
    echo -e "${YELLOW}Getting CloudFront distribution ID from Terraform outputs...${NC}"
    DISTRIBUTION_ID=$(cd ../../platform && terraform output -raw cloudfront_distribution_id 2>/dev/null || echo "")
fi

# Validate required variables
if [ -z "$S3_BUCKET" ]; then
    echo -e "${RED}Error: S3 bucket name not set. Please set S3_BUCKET environment variable or ensure terraform outputs are available${NC}"
    exit 1
fi

# Change to src directory for Pelican commands
cd "$SRC_DIR"

# Check if Pelican is available
if ! command -v pelican &> /dev/null; then
    echo -e "${YELLOW}Pelican not found. Attempting to install...${NC}"
    pip install pelican markdown
fi

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
make clean

# Build the site
echo -e "${YELLOW}Building Pelican site...${NC}"
make html

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to build Pelican site${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Pelican site built successfully${NC}"

# Go back to parent directory for deployment
cd ..

# Sync files to S3
echo -e "${YELLOW}Syncing files to S3 bucket: ${S3_BUCKET}${NC}"
aws s3 sync "$SRC_DIR/$OUTPUT_DIR/" "s3://${S3_BUCKET}/${SITE_NAME}/" \
    --delete \
    --cache-control "max-age=31536000,public" \
    --exclude "*.html" \
    --include "*.html" \
    --cache-control "max-age=0,no-cache"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Files synced to S3 successfully${NC}"
else
    echo -e "${RED}✗ Failed to sync files to S3${NC}"
    exit 1
fi

# Invalidate CloudFront cache if distribution ID is available
if [ ! -z "$DISTRIBUTION_ID" ]; then
    echo -e "${YELLOW}Invalidating CloudFront cache...${NC}"
    INVALIDATION_ID=$(aws cloudfront create-invalidation \
        --distribution-id "$DISTRIBUTION_ID" \
        --paths "/${SITE_NAME}/*" \
        --query 'Invalidation.Id' \
        --output text)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ CloudFront cache invalidation created (ID: ${INVALIDATION_ID})${NC}"
    else
        echo -e "${RED}✗ Failed to create CloudFront cache invalidation${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Skipping CloudFront cache invalidation${NC}"
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}Site should be available at: https://${SITE_NAME}${NC}"
