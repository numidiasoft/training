data "aws_ami" "blue" {
  most_recent = true

  filter {
    name   = "name"
    values = ["blue-green-1561529731"]
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

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}


resource "aws_security_group" "ec2" {
  count       = var.enable_blue ? 1 : 0
  name        = "terraform-blue-green-ec2"
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

resource "aws_launch_configuration" "blue" {
  count           = var.enable_blue ? 1 : 0
  name_prefix     = "terraform-blue-green-"
  image_id        = data.aws_ami.blue.id
  instance_type   = "t2.micro"
  key_name        = "blue-green"
  security_groups = aws_security_group.ec2.*.id
  user_data       = <<EOF
#! /bin/bash
node /home/ubuntu/app/server.js
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "blue" {
  count = var.enable_blue ? 1 : 0
  name_prefix = "terraform-blue-green-"
  launch_configuration = aws_launch_configuration.blue.0.name
  min_size = 1
  max_size = 1
  vpc_zone_identifier = aws_subnet.public.*.id

  lifecycle {
    create_before_destroy = true
  }
}

##########
#  ALB ASG 
##########
resource "aws_security_group" "lb_sg" {
  count = var.enable_blue ? 1 : 0
  name = "terraform-blue-green"
  description = "Allow TLS inbound traffic"
  vpc_id = "${aws_vpc.this.id}"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "blue" {
  count = var.enable_blue ? 1 : 0
  name = "terraform-blue-green"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_sg.0.id]
  subnets = aws_subnet.public.*.id

  enable_deletion_protection = false


  tags = {
    Environment = "Blue"
  }
}

resource "aws_alb_listener" "blue" {
  count = var.enable_blue ? 1 : 0
  load_balancer_arn = "${aws_alb.blue.0.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.blue.0.arn}"
    type = "forward"
  }
}


resource "aws_alb_target_group" "blue" {
  count = var.enable_blue ? 1 : 0
  name = "terraform-blue-green"
  port = 9000
  protocol = "HTTP"
  target_type = "instance"
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

resource "aws_autoscaling_attachment" "blue" {
  count = var.enable_blue ? 1 : 0
  alb_target_group_arn = aws_alb_target_group.blue.0.arn
  autoscaling_group_name = aws_autoscaling_group.blue.0.id
}

