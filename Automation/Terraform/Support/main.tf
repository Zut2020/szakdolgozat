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

data "aws_security_group" "default-sg" {
  name = "default"
}

resource "aws_security_group_rule" "ssh-rule" {
  description       = "SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default-sg.id
}

resource "aws_security_group_rule" "detector-rule" {
  description       = "Detector port"
  type              = "ingress"
  from_port         = 40674
  to_port           = 40674
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default-sg.id
}

resource "aws_security_group_rule" "ocr-rule" {
  description       = "Detector port"
  type              = "ingress"
  from_port         = 40675
  to_port           = 40675
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.default-sg.id
}