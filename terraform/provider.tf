terraform {
  backend "s3" {
    bucket         = "joeyomi-terraform-state"
    dynamodb_table = "tf-remote-state-lock"
    key            = "tf-state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.assume_role_arn
    external_id  = var.assume_role_external_id
    session_name = "TerraformSession"
  }
}
