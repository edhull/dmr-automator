provider "aws" {
  region     = var.aws_region
}

terraform {
  required_version = ">= 0.13.0"
  backend "s3" {
    region = var.aws_region
  }
}
