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

resource "aws_ecr_repository" "detector-lambda-ecr" {
  name = "detector-lambda"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ocr-lambda-ecr" {
  name = "ocr-lambda"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}

data "aws_ecr_image" "detector-lambda-docker" {
  repository_name = "detector-lambda"
  image_tag       = "latest"
}

data "aws_ecr_image" "ocr-lambda-docker" {
  repository_name = "ocr-lambda"
  image_tag       = "latest"
}

resource "aws_lambda_function" "detector" {
  function_name                  = "detector-function"
  role                           = data.aws_iam_role.labrole.arn
  timeout                        = 600
  package_type                   = "Image"
  memory_size                    = 1536
  image_uri                      = "${aws_ecr_repository.detector-lambda-ecr.repository_url}@${data.aws_ecr_image.detector-lambda-docker.image_digest}"
  reserved_concurrent_executions = 1
}

resource "aws_lambda_function" "ocr" {
  function_name                  = "ocr-function"
  role                           = data.aws_iam_role.labrole.arn
  timeout                        = 600
  package_type                   = "Image"
  memory_size                    = 512
  image_uri                      = "${aws_ecr_repository.ocr-lambda-ecr.repository_url}@${data.aws_ecr_image.ocr-lambda-docker.image_digest}"
  reserved_concurrent_executions = 10
}

data "aws_s3_bucket" "parking" {
  bucket = "parking-g1t1sz"
}

data "aws_s3_bucket" "cars" {
  bucket = "cars-g1t1sz"
}

resource "aws_s3_bucket_notification" "detector-trigger" {
  bucket = data.aws_s3_bucket.parking.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.detector.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = "parking_cars.png"
  }
}

resource "aws_s3_bucket_notification" "ocr-trigger" {
  bucket = data.aws_s3_bucket.cars.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ocr.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "detector-permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.detector.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${data.aws_s3_bucket.parking.id}"
}

resource "aws_lambda_permission" "ocr-permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ocr.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${data.aws_s3_bucket.cars.id}"
}