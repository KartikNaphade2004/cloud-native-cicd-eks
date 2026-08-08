terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # For a portfolio project, local state is fine. For real teams you would
  # use a remote backend (S3 + DynamoDB lock). Left here as documentation:
  #
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "cloud-native-cicd-eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "my-tf-locks"
  #   encrypt        = true
  # }
}
