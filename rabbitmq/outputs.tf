output "erlang_cookie" {
  value = "${random_string.erlang_cookie.result}"
}

output "amqp_tg_arn" {
  description = "Target group ARN with which the rabbitmq instances are attached for AMQP communication."
  value = "${aws_lb_target_group.rabbitmq_tg.arn}"
}

output "web_tg_arn" {
  description = "Target group ARN for rabbitMQ web UI dashboard"
  value = "${aws_lb_target_group.rabbitmq_web_tg.arn}"
}

output "rabbit_autoscaling_group" {
  description = "Autoscaling group for the rabbitmq cluster."
  value = "${aws_autoscaling_group.rabbitmq_asg.name}"
}
