# AWS RabbitMQ cluster

> Setup a rabbitmq cluster in autoscaling envrironment on AWS, this uses rabbimq aws-peer-discovery plugin to find nodes in Autoscaling group.
The rabbit_access_key and secret provided in the configuration must only have read only permission, so they don't do anything bad.

Before doing anything first setup the remote state for the project, a remote-state is the remote storage place for terraform artifacts which is the mapping of artifacts with the real world resources.

```bash
$ cd remote-state

$ cat README.md 
```

Now let's spin our RabbitMQ cluster

> Copy the `terraform.tfvars.example` to `terraform.tfvars` and edit the variables inside the file.

While working with the terraform configurations we should select the remote-state to use for the backend configuration. We have not hardcoded the backend configuration values, which means these configurations should be provided via a file using `-backend-config=PATH` flag for the terraform command.

See [Terraform backend configuration](https://www.terraform.io/docs/backends/config.html)

```bash
$ cat terraform.backend
bucket = "example-tf-remote-state-storage-s3"
dynamodb_table = "example-terraform-state-lock-dynamo"
region = "ap-southeast-1"

$ cat terraform.tfvars
aws_access_key = "AKIAIOSFODNN7EXAMPLE"
aws_secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

...
...

$ terraform init -backend-config=terraform.backend

$ terraform plan -backend-config=terraform.backend

$ terraform apply -backend-config=terraform.backend
```

### Note

This is not a production ready setup for rabbitmq cluster, I haven't optimized the instances for the particular use case, neither have I taken into account security for the cluster setup. This project is just for learning purpose and to show how clustering can be achieved in AWS for rabbitmq.

I don't intend to make this project production ready, but would love have contributions and thoughts on how we can improve the implementation.
