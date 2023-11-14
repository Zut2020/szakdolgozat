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

resource "aws_ecr_repository" "detector-ecr" {
  name = "detector"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "ocr-ecr" {
  name = "ocr"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main"]
  }
}

data "aws_security_groups" "detector" {
  filter {
    name   = "tag:Name"
    values = ["detector-docker"]
  }
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}


data "aws_subnet" "docker" {
  filter {
    name   = "tag:Name"
    values = ["docker-subnet"]
  }
}

data "aws_subnets" "docker" {
  filter {
    name   = "tag:Name"
    values = ["docker-subnet"]
  }
}


resource "aws_lb" "docker-lb" {
  name               = "docker-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [data.aws_subnet.docker.id]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "docker" {
  name        = "docker-tg"
  port        = 8080
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_lb_listener" "docker" {
  load_balancer_arn = aws_lb.docker-lb.arn
  port              = "8080"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.docker.arn
  }
}

resource "aws_ecs_cluster" "detector-cluster" {
  name = "detector-cluster"
}

resource "aws_cloudwatch_log_group" "detector" {
  name = "/ecs/detector-task"
}

resource "aws_ecs_task_definition" "detector-task" {
  family                   = "detector-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = data.aws_iam_role.labrole.arn
  task_role_arn            = data.aws_iam_role.labrole.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "detector"
      image     = "181034493839.dkr.ecr.us-east-1.amazonaws.com/detector"
      essential = true
      portMappings = [
        {
          name          = "detector-8080-tcp"
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/detector-task"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
        secretOptions = []
      }
    },
    {
      name      = "ocr"
      image     = "181034493839.dkr.ecr.us-east-1.amazonaws.com/ocr"
      essential = true
      portMappings = [
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/detector-task"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
        secretOptions = []
      }
    }
  ])
}

resource "aws_ecs_service" "detector-service" {
  name                 = "detector-service"
  cluster              = aws_ecs_cluster.detector-cluster.id
  task_definition      = aws_ecs_task_definition.detector-task.arn
  desired_count        = 1
  depends_on           = [aws_ecs_task_definition.detector-task]
  force_new_deployment = true
  launch_type          = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.docker.ids
    security_groups  = data.aws_security_groups.detector.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.docker.arn
    container_name   = "detector"
    container_port   = 8080
  }
}