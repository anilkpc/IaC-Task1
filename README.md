# IaC-Task1

This repo contains the Terraform files for deploying a web server on AWS.

## Quick Start

1. Sign up for an AWS account
2. Install Terraform
3. Configure your AWS credentials as environment variables:<br/>
    export AWS_ACCESS_KEY_ID=...<br/>
    export AWS_SECRET_ACCESS_KEY=...
4. Create the resource creation files by pulling from the repo
5. Run terraform init
6. Run terrfaorn plan
7. If the plan looks good, run terraform apply to deploy the resources and code into your AWS account
8. Login to AWS console, to check the state of your deployments

## Next Steps

1. The web application runtime can be created as a Docker image and pushed to ECR
2. Deployment pipleine can be used to build the application executable and again build as a new image using the previous step image as base image
3. Monitoring of the applications can be setup using AWS CloudWatch or external applications like Prometheus
4. Log aggregation can be done using ELK
