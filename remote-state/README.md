# Remote State

> This module configure the remote state for terraform backend.

This module creates a s3 bucket for storing the terraform state and a DynamoDB table to enable state locking when using terraform states. This should be the first module that runs when configuring the infrastructure. It creates the necessery terraform backend requirements to setup the infrastructure.

To setup remote-state:

```bash
# Create a `terraform.tfvars` file in the current directory with aws access and secret key.
$ cat terraform.tfvars
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
prefix = "example"

$ terraform init

$ terraform plan

$ terraform apply
```
