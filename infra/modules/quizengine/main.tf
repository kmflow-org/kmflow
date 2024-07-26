locals {
    name_prefix = "${var.prefix}-${var.env}"
}

# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for instances
resource "aws_security_group" "instance_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Allow traffic only from ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Data source to fetch public subnets
data "aws_subnets" "public" {
  filter {
    name   = "tag:type"
    values = ["public"]
  }
  filter {
    name   = "tag:env"
    values = [var.env]
  }
}

# Data source to fetch private subnets
data "aws_subnets" "private" {
  filter {
    name   = "tag:type"
    values = ["private"]
  }
  filter {
    name   = "tag:env"
    values = [var.env]
  }
}


# Create the ALB
resource "aws_lb" "quizengine-alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false
}

# Create Target Group
resource "aws_lb_target_group" "quizengine-tg" {
  name     = "${local.name_prefix}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    interval            = 10
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

# Create Listener
resource "aws_lb_listener" "quizengine-lstnr" {
  load_balancer_arn = aws_lb.quizengine-alb.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quizengine-tg.arn
  }
}

# Data source to fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#  User Data
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh.tpl")
  vars = {
    release_version = var.release_version
  }
}

# Launch Template
resource "aws_launch_template" "quizengine-lt" {
  name   = "${local.name_prefix}-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  user_data     = base64encode(data.template_file.user_data.rendered)
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.quizengine_instance_profile.name
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "quizengine-asg" {
  name = "${local.name_prefix}-asg"
  desired_capacity     = 1
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = data.aws_subnets.private.ids
  launch_template {
    id      = aws_launch_template.quizengine-lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.quizengine-tg.arn]

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "target_tracking" {
  name                   = "target-tracking-scaling-policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.quizengine-asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}
