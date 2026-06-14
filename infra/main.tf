terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "music-stats-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "music-stats-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
