data "aws_ami" "green" {
  most_recent = true

  filter {
    name   = "name"
    values = ["blue-green-1561808009"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${data.aws_caller_identity.current.account_id}"] # Canonical
}

#######################
# AUTOSCALING EC2 GROUP
#######################


resource "aws_security_group" "ec2-green" {
  count       = var.enable_green ? 1 : 0
  name        = "terraform-green-ec2"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.this.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "green" {
  count           = var.enable_green ? 1 : 0
  name_prefix     = "terraform-blue-green-"
  image_id        = data.aws_ami.green.id
  instance_type   = "t2.micro"
  security_groups = aws_security_group.ec2-green.*.id
  user_data       = <<EOF
#! /bin/bash
node /home/ubuntu/app/server.js
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  count = var.enable_green ? 1 : 0
  name_prefix = "terraform-blue-green-"
  launch_configuration = aws_launch_configuration.green.0.name
  min_size = 1
  max_size = 1
  vpc_zone_identifier = aws_subnet.public.*.id

  lifecycle {
    create_before_destroy = true
  }
}

#########
# ALB ASG
#########


resource "aws_security_group" "green-lb-sg" {
  count = var.enable_green ? 1 : 0
  name = "terraform-green-alb"
  description = "Allow TLS inbound traffic"
  vpc_id = "${aws_vpc.this.id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.body)}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "green" {
  count = var.enable_green ? 1 : 0
  name = "green"
  internal = false
  load_balancer_type = "application"
  security_groups = ["${aws_security_group.green-lb-sg.0.id}"]
  subnets = aws_subnet.public.*.id

  enable_deletion_protection = false

  tags = {
    Environment = "production"
    Name = "Blue"
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  count = var.enable_green ? 1 : 0
  name = "green"
  port = "9000"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.this.id}"

  health_check {
    healthy_threshold = 3
    unhealthy_threshold = 10
    timeout = 5
    interval = 10
    path = "/"
    port = "9000"
  }
}

resource "aws_lb_listener" "green-front-end" {
  count = var.enable_green ? 1 : 0
  load_balancer_arn = "${aws_lb.green.0.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = "${aws_alb_target_group.alb_target_group.0.arn}"

  }
}


resource "aws_autoscaling_attachment" "green" {
  count = var.enable_green ? 1 : 0
  alb_target_group_arn = "${aws_alb_target_group.alb_target_group.0.arn}"
  autoscaling_group_name = "${aws_autoscaling_group.green.0.id}"
}
