terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

#Support

resource "aws_dynamodb_table" "parking-db" {
  name           = "Parking"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "CarID"

  attribute {
    name = "CarID"
    type = "N"
  }
}

resource "aws_s3_bucket" "parking-storage" {
  bucket = "parking-g1t1sz"
}