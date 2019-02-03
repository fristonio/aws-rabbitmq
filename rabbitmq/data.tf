# Generate a random string as erlang cookie for the cluster
resource "random_string" "erlang_cookie" {
  length = 16
  special = false
}

data "template_file" "setup_template" {
  template = "${file("${path.module}/setup.sh")}"

  vars {
    rabbit_access_key    = "${var.rabbit_access_key}"
    rabbit_secret_key    = "${var.rabbit_secret_key}"
    rabbitmq_admin       = "${var.rabbitmq_admin_user}"
    rabbitmq_admin_pass  = "${var.rabbitmq_admin_pass}"
    erlang_cookie        = "${random_string.erlang_cookie.result}"
  }
}

# Create a AWS IAM role policy document, for rabbitmq cluster.
data "aws_iam_policy_document" "policy_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
