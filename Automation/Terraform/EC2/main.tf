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

resource "aws_instance" "detector" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.medium"
  key_name      = "szakdolgozat-key"

  root_block_device {
    volume_size = 15
  }

  tags = {
    Name = "Detector VM"
  }
}

#Output
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.detector.public_ip
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tpl", { public_ip = aws_instance.detector.public_ip })
  filename = "${path.module}/../../Ansible/inventory.yml"
}