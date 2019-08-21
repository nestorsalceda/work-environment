data "aws_ami" "amazon_linux_ecs" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_iam_role" "this" {
  name = "${var.cluster-name}_ecs_instance_role"
  path = "/ecs/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.cluster-name}_ecs_instance_profile"
  role = aws_iam_role.this.name
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_cloudwatch_role" {
  role = aws_iam_role.this.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

locals {
  ecs_node_user_data = <<USERDATA
#!/bin/bash

# ECS config
{
  echo "ECS_CLUSTER=${var.cluster-name}"
} >> /etc/ecs/ecs.config

{
  echo "ECS_AVAILABLE_LOGGING_DRIVERS=[\"awslogs\",\"fluentd\"]"
} >> /etc/ecs/ecs.config

start ecs

echo "Done"
USERDATA
}

resource "aws_launch_configuration" "this" {
  name_prefix                 = "${var.cluster-name}-"
  image_id                    = data.aws_ami.amazon_linux_ecs.image_id
  instance_type               = "m4.large"
  iam_instance_profile        = aws_iam_instance_profile.this.name
  security_groups             = [aws_vpc.this.default_security_group_id]
  user_data                   = local.ecs_node_user_data
  # TODO: be able to bootstrap machines without public_ip
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.this.id}"
  max_size             = 2
  min_size             = 1
  name                 = var.cluster-name
  vpc_zone_identifier  = "${aws_subnet.this[*].id}"
}
