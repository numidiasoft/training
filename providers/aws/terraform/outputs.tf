output "aws_blue_lb" {
  value = "${aws_alb.blue.0.dns_name}"
}

