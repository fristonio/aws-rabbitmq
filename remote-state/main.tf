# Setup the AWS terraform provider
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# Create a DynamoDB table to perform state locking for terraform
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
  name = "${var.terraform_dynamodb_table}"
  hash_key = "LockID"
  read_capacity = 10
  write_capacity = 10
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

# Create a S3 bucket to store terraform state remotely.
resource "aws_s3_bucket" "terraform-state-storage-s3" {
  bucket = "${var.terraform_remote_state_bucket}"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Name = "S3 Remote Terraform State Storage."
  }
}
