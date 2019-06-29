output "aws_green_lb" {
  value = "${aws_lb.green.0.dns_name}"
}


output "aws_blue_lb" {
  value = "${aws_alb.blue.0.dns_name}"
}

