# ---------------------------------------------------------
# Setup IAM roles for rabbitmq cluster nodes, required for
# peer discovery in cluster, this role is added to all the
# instances.
# ---------------------------------------------------------
resource "aws_iam_role" "role" {
  name               = "${var.service_prefix}-iam-role"
  assume_role_policy = "${data.aws_iam_policy_document.policy_doc.json}"
}

resource "aws_iam_role_policy" "policy" {
  name = "${var.service_prefix}-iam-policy"
  role = "${aws_iam_role.role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingInstances",
        "ec2:DescribeInstances"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  name_prefix = "${var.service_prefix}"
  role        = "${aws_iam_role.role.name}"
}

# -----------------------------------------------------------------
# Security Group for rabbitmq nodes, this descibes the inbound and
# outbound connections available for the node instance.
# The ports needed by rabbitmq itself for self communication are
# 4369 - epmd port
# 5672 - AMQP port
# 15672 - Dashboard port
# 25672 - Internal communication
# -----------------------------------------------------------------
resource "aws_security_group" "rabbitmq_nodes" {
  name        = "${var.service_prefix}-cluster-sg"
  vpc_id      = "${var.vpc_id}"
  description = "Security Group for the rabbitmq cluster node."

  ingress {
    protocol        = -1
    from_port       = 0
    to_port         = 0
    self            = true
  }

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = ["${var.ssh_sg_id}"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 4369
    to_port         = 4369
    self            = true
  }

  # We use network load balancer for this port to forward TCP traffic
  # Network load balancer as of now does not allow us to associate security
  # groups with them. Therefore we are allowing access using a CIDR block.
  ingress {
    protocol        = "tcp"
    from_port       = 5672
    to_port         = 5672
    cidr_blocks     = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 15672
    to_port         = 15672
    security_groups = ["${var.alb_sg_id}"]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 25672
    to_port         = 25672
    self            = true
  }

  egress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0

    cidr_blocks     = [
      "0.0.0.0/0",
    ]
  }

  tags {
    Name = "${var.service_prefix}-cluster-sg"
  }
}

# --------------------------------------------------------------------
# Launch template for EC2 instances running as rabbitmq cluster nodes
# UserData specifies the script to run during the launch of instance 
# which will setup the rabbitmq node, we are for now defaulting the EBS
# volume to 50 GB which should suffice all the use cases.
# --------------------------------------------------------------------
resource "aws_launch_template" "rabbitmq" {
  name = "${var.service_prefix}lt"
  description = "This launch template is for generating an instance for RabbitMQ cluster."

  # We are attaching a 50GB volume to the instance, which should be enough
  # Given the use case of the instance.
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 50
    }
  }

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  # IAM profile role to attach the instance with.
  iam_instance_profile = {
    arn = "${aws_iam_instance_profile.profile.arn}"
  }

  # Ubuntu 16.04 xenial AMI
  image_id = "ami-0eb1f21bbd66347fe"
  disable_api_termination = true
  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "${var.ec2_instance_type}"
  key_name = "${var.key_name}"

  network_interfaces {
    associate_public_ip_address = false
    subnet_id = "${var.subnet_id}"
    security_groups = ["${aws_security_group.rabbitmq_nodes.id}"]
  }

  placement {
    availability_zone = "${var.aws_region}"
  }

  # In launch templates we cannot assign vpc_security_group_id when we have specified
  # the security group for a network interface.
  # vpc_security_group_ids = ["${aws_security_group.rabbitmq_nodes.id}"]

  tag_specifications {
    resource_type = "instance"

    tags {
      Name = "${var.service_prefix}-lt"
    }
  }

  # Base64Encode the user_data for launch template.
  user_data = "${base64encode(data.template_file.setup_template.rendered)}"
}

# -----------------------------------------------------------------
# Target group to attach the autoscaling group to, there are two
# target groups one for rabbitmq WebUI and other for the cluster
# messaging queue.
# -----------------------------------------------------------------
resource "aws_lb_target_group" "rabbitmq_tg" {
  name     = "${var.service_prefix}-cluster-tg"
  port     = 5672
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"

  health_check = {
    port = 5672
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "rabbitmq_web_tg" {
  name     = "${var.service_prefix}-web-tg"
  port     = 15672
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check = {
    path = "/"
    port = 15672
    protocol = "HTTP"
  }
}

# ---------------------------------------------------------------------
# Specifies the autoscaling group and autoscaling policy for the group
# ---------------------------------------------------------------------
# Autoscaling policy specifying to scale-out if the average CPU utilization
# exceeds 75%.
resource "aws_autoscaling_policy" "rabbitmq_asp" {
  name                   = "${var.service_prefix}-as-policy"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.rabbitmq_asg.name}"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration = {
    predefined_metric_specification =  {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

resource "aws_autoscaling_group" "rabbitmq_asg" {
  name                 = "${var.service_prefix}-asg"
  min_size             = "${var.min_instances}"
  max_size             = "${var.max_instances}"
  desired_capacity     = "${var.desired_instances}"
  
  launch_template = {
    id      = "${aws_launch_template.rabbitmq.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier = ["${var.subnet_id}"]
  target_group_arns = ["${aws_lb_target_group.rabbitmq_tg.arn}", "${aws_lb_target_group.rabbitmq_web_tg.arn}"]

  tag {
    key                 = "Name"
    value               = "${var.service_prefix}-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
