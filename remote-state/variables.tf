variable aws_access_key {
  type = "string"
}

variable aws_secret_key {
  type = "string"
}

variable "aws_region" {
  description = "AWS region for deployment."
  default = "ap-southeast-1"
}

variable "terraform_remote_state_bucket" {
  type = "string"
  description = "S3 bucket name of terraform remote state storage on AWS."
  default = "tf-remote-state-storage-s3"
}

variable "terraform_dynamodb_table" {
  type = "string"
  description = "DynamoDB table for Terraform to perform state locking when using remote state."
  default = "terraform-state-lock-dynamo"
}
