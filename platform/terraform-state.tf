# Terraform State Storage Configuration

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-multi-hosting-${random_string.state_suffix.result}"

  tags = {
    Name      = "terraform-state-multi-hosting"
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "terraform-state-storage"
  }
}

# Enable versioning for state bucket
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for state bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks-multi-hosting"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "terraform-locks-multi-hosting"
    Project   = "multi-hosting"
    ManagedBy = "terraform"
    Purpose   = "terraform-state-locking"
  }
}

# Random suffix for unique state bucket name
resource "random_string" "state_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Random suffix for unique content bucket name
resource "random_string" "content_suffix" {
  length  = 8
  special = false
  upper   = false
}
