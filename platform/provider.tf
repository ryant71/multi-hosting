terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration moved to backend.tfvars for security
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1" # ACM certificates for CloudFront must be in us-east-1

  default_tags {
    tags = {
      Project     = "multi-hosting"
      ManagedBy   = "terraform"
      Environment = "production"
      Region      = "us-east-1"
    }
  }
}

provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"

  default_tags {
    tags = {
      Project     = "multi-hosting"
      ManagedBy   = "terraform"
      Environment = "production"
      Region      = "eu-central-1"
    }
  }
}

# Default provider (set to EU for most resources)
provider "aws" {
  region = "eu-central-1" # Default to EU (Frankfurt)

  default_tags {
    tags = {
      Project     = "multi-hosting"
      ManagedBy   = "terraform"
      Environment = "production"
      Region      = "eu-central-1"
    }
  }
}
