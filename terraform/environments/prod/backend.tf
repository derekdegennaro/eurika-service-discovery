terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Replace these values with your S3 bucket and DynamoDB table
    bucket         = "your-terraform-state-bucket"
    key            = "eurika-service-discovery/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-terraform-locks-table"
    encrypt        = true
  }
}
