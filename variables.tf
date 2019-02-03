variable "rabbit_access_key" {}
variable "rabbit_secret_key" {}

variable "rabbitmq_admin_user" {}
variable "rabbitmq_admin_pass" {}

variable "vpc_id" {}
variable "alb_sg_id" {}
variable "ssh_sg_id" {}
variable "subnet_id" {}

variable "rabbit_ec2_instance_type" {
  description = "Type of EC2 instance to use for RabbitMQ node in the cluster."
  default     = "m5.large"
}
