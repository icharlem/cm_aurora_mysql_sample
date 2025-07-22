# versions.tf - Terraform and provider version constraints

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Uncomment and configure the backend if you want to store state remotely
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "aurora-mysql/terraform.tfstate"
  #   region = "us-west-2"
  # }
}
