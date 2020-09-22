# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Deploy a web application on AWS with ASG and ELB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# --------------------------------------------
# Mention the version of terraform to be used


terraform {
  required_version = ">= 0.13"
}


# ------------------------------------------------
# Configure the AWS region to deploy the resources

provider "aws" {
  region = "eu-west-2"
}


# ------------------
# Get the list of AZ

data "aws_availability_zones" "all" {}


# --------------------------------------------
# Create the EC2 resource launch configuration

resource "aws_launch_configuration" "infra-launchconfig" {
  # Amazon Linux 2 AMI (HVM), SSD Volume Type in ap-south-1
  name_prefix     = "infra-launchconfig"
  image_id        = "ami-09b89ad3c5769cca2"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sg_ec2_instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World!!!!" > index.html
              nohup busybox httpd -f -p "${var.elb_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}


#--------------------------------------------------
# Create VPC

resource "aws_vpc" "vpc-infra-task" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"
  tags = {
    Name = "vpc-infra-task"
  }
}

# --------------------------------------------------
# Create the ASG to be used with launch configration

resource "aws_autoscaling_group" "asg_infra_task1" {
  name                 = "asg_infra_task1"
  launch_configuration = aws_launch_configuration.infra-launchconfig.id
  availability_zones   = data.aws_availability_zones.all.names

  min_size = 1
  max_size = 2

  load_balancers    = [aws_elb.elb-task1.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

# ----------------------------------------------------------------------
# Create the Security group to be applied for each EC2 instance created

resource "aws_security_group" "sg_ec2_instance" {
  vpc_id      = aws_vpc.vpc-infra-task.id
  name = "sg_ec2_instance"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# Create an elasctic load balancer to route traffic to EC2 instances


resource "aws_elb" "elb-task1" {
  name               = "elb-task1"
  security_groups    = [aws_security_group.elb_sg.id]
  availability_zones   = data.aws_availability_zones.all.names

  listener {
    instance_port     = var.elb_port
    instance_protocol = "http"
    lb_port           = var.elb_port
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 400
}


# ---------------------------------------------------------------------------------------------------------------------
# Create the security group to be applied to elb

resource "aws_security_group" "elb_sg" {
  name = "elb_sg"

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = var.elb_port
    to_port     = var.elb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
