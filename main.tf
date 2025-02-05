# ─────────────────────────────────────────────────────────────
# Providers Configuration
# ─────────────────────────────────────────────────────────────
provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.84.0"
    }
  }

  backend "s3" {
    bucket  = "danb-kops-state"
    key     = "vpc365/state/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}

# ─────────────────────────────────────────────────────────────
# VPC Module
# ─────────────────────────────────────────────────────────────
module "aws_vpc" {
  source              = "./modules/vpc"
  vpc_name            = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets

  tags = {
    Name        = "vpc-365-scores"
    Environment = "test"
    CreatedBy   = "Dan Bar-Or"
    Date        = "03-Feb-2025"
  }
}

