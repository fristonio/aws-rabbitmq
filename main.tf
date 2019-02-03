# Setup the AWS terraform provider
# We currently only operate in singapore(ap-southeast-1) region.
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Terraform version requirements and backend setup.
# We are using S3 as terraform backend with DynamoDB table for state locking purposes.
# As of terraform version 0.11.10 we cannot use interpolation in terraform block
# so the bucket name and DynamoDB table name are hardcoded rahter than using a variable.
terraform {
  required_version = ">= 0.11.3"

  backend "s3" {
    bucket         = ""
    dynamodb_table = ""
    key            = "test/terraform_state"
    region         = "ap-southeast-1"
    encrypt        = true
  }
}

# After this module has been initialized you need to configure your load balancers to 
# point to the required instances on the required ports using target groups.
# For AMQP communication use the target group ARN and point a network load balancer 
# at port 5672 of the target group, or you can connect to a instance in the cluster directly
# without using a load balancer.
# For web dashboard UI, use the application load balancer in conjunction with a route 53 rule
# to point to the Web UI target group on the port 15672.
module "rabbitmq_cluster" {
  source = "./rabbitmq"
  
  rabbit_access_key   = "${var.rabbit_access_key}"
  rabbit_secret_key   = "${var.rabbit_secret_key}"

  rabbitmq_admin_user = "${var.rabbitmq_admin_user}"
  rabbitmq_admin_pass = "${var.rabbitmq_admin_pass}"

  vpc_id              = "${var.vpc_id}"
  subnet_id           = "${var.subnet_id}"
  alb_sg_id           = "${var.alb_sg_id}"
  ssh_sg_id           = "${var.ssh_sg_id}"
  ec2_instance_type   = "${var.rabbit_ec2_instance_type}"

  service_prefix      = "${var.prefix}"
}
