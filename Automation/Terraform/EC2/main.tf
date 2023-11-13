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

resource "aws_key_pair" "szakdolgoat-key-pair" {
  key_name   = "szakdolgozat-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDV5fE1sUD4a10DM3TAtXkqb/SVtPvgdOCjRYl5Jhu9cGN4ANiUg5txOM+wXHWixLXespdEU6E60Rexp/GGXzxa9+JZGtw5H47J5dyYxCpjPBKW+bE0qD79xngx45+Ji0HeRZWMMEgrDdJShQ+1KBwrypyhmovqi493e7KtjY3JUQn0ofDxgQntkZKUybYN05OWVwmcnkn0YLxsWuGZLKnj4qs91scoFlqPqhbavHdKBLbSDAc8j41yO3tc+oLbWY/MSUDUpgFrnzyBWm6y02iifaXO10DnyZ+co0/DSeFgPTBhMFJjzaWqoQSpRwYz2lL+i88RGZom53z1iNgfKApBgjIouKyt9vpbYhbHlTzPyOI6rIqN0XvLIRYWCmDQPf73tRWpvf7Olw+V88bCnCdp7uPYtYyC50FaFLgSRv2dCT1RjWBhb/t8TdqcNGxj3ogsx1fSvHEqvGosCGTDV5nG0jV7Do6b8W9hDOKRpiqVazYmNUQbHsCZlbVmEIKeMICb8RjOQfidMLFRMnfa+wIRk0j0jYuRJ79FBrq0TRMey2yglTGXtKWvoGUOWN8piU32kEl8f8yKXq93yghu1VhPkdRj8xt3/JmeyoF7i6ZFEkjl+XooxU1unsEsXAE62EvDMeFYRW2DTpdmgCUJ25xuOl46/uFrFAQR5p5IZ/wNfw== pompos.balazs@gmail.com"
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["main"]
  }
}

data "aws_subnet" "ec2" {
  filter {
    name   = "tag:Name"
    values = ["ec2-subnet"]
  }
}

data "aws_security_groups" "detector" {
  filter {
    name   = "tag:Name"
    values = ["detector-ec2"]
  }
}

resource "aws_instance" "detector" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.medium"
  key_name               = "szakdolgozat-key"
  subnet_id              = data.aws_subnet.ec2.id
  vpc_security_group_ids = data.aws_security_groups.detector.ids
  private_ip             = "10.0.1.100"
  iam_instance_profile   = "LabInstanceProfile"

  root_block_device {
    volume_size = 15
  }

  tags = {
    Name = "Detector VM"
  }
}


resource "aws_lb" "ec2-lb" {
  name               = "ec2-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [data.aws_subnet.ec2.id]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "ec2" {
  name        = "ec2-tg"
  port        = 40674
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "attachment" {
  target_group_arn = aws_lb_target_group.ec2.arn
  target_id        = aws_instance.detector
  port             = 40674
}

resource "aws_lb_listener" "detector" {
  load_balancer_arn = aws_lb.ec2-lb.arn
  port              = "40674"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2.arn
  }
}


#Output
output "load_balancer_address" {
  description = "Load balancer DNS address"
  value       = aws_lb.ec2-lb.dns_name
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.detector.public_ip
}

resource "local_file" "inventory" {
  content  = templatefile("${path.module}/inventory.tpl", { public_ip = aws_instance.detector.public_ip })
  filename = "${path.module}/../../Ansible/inventory.yml"
}
