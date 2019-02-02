variable "service_prefix" {
  type        = "string"
  description = "Prefix string to attach to names when creating a resource."
  default     = "example" 
}

variable rabbit_access_key {
  type        = "string"
  description = "Access key for rabbitmq cluster node, required for peer discovery using aws peer discovery plugin"
}

variable rabbit_secret_key {
  type = "string"
  description = "Secret key for rabbitmq cluster node, required for peer discovery using aws peer discovery plugin"
}

variable "rabbitmq_admin_user" {
  type        = "string"
  description = "Name of RabbitMQ cluster admin."
}

variable "rabbitmq_admin_pass" {
  type        = "string"
  description = "Admin user password for RabbitMQ node."
}

variable "min_instances" {
  description = "Minimum number of RabbitMQ instances in autoscaled cluster."
  default     = 2
}

variable "desired_instances" {
  description = "Desired number of RabbitMQ instances in the autoscaled cluster."
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of RabbitMQ instances in the autoscaled cluster."
  default     = 4
}

variable "subnet_id" {
  type        = "string"
  description = "Sprint VPC subnet ID, to identify VPC zone."
}

variable "vpc_id" {
  type        = "string"
  description = "VPC ID for Sprint to deploy the RabbitMQ cluster in."
}

variable "alb_sg_id" {
  type        = "string"
  description = "Sprint application load balancer ID, the WebUI for the cluster will be attached to this load balancer."
}

variable "ssh_sg_id" {
  type        = "string"
  description = "Security group ssh."
}

variable "ec2_instance_type" {
  type        = "string"
  description = "Type of the instance to create for RabbitMQ servers."
}
