#! /bin/bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 181034493839.dkr.ecr.us-east-1.amazonaws.com
docker build -t detector .
docker tag detector:latest 181034493839.dkr.ecr.us-east-1.amazonaws.com/detector:latest
docker push 181034493839.dkr.ecr.us-east-1.amazonaws.com/detector:latest