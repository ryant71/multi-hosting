terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure backend as needed
  # backend "s3" {
  #   bucket         = "terraform-state-bucket"
  #   key            = "multi-hosting/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = "us-east-1" # ACM certificates for CloudFront must be in us-east-1
  
  default_tags {
    tags = {
      Project     = "multi-hosting"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}
