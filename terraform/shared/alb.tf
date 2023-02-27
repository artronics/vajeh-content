resource "aws_lb" "alb" {
  name               = local.prefix
  internal           = true
  load_balancer_type = "application"

  subnets         = local.subnet_ids
  security_groups = [aws_security_group.alb_security_group.id]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    enabled = true
  }
}

resource "aws_security_group" "alb_security_group" {
  name   = "${local.prefix}-alb"
  vpc_id = local.vpc_id

  egress {
    protocol    = "tcp"
    from_port   = 9000
    to_port     = 9000
    cidr_blocks = local.cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = local.cidr_blocks
  }
}
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${local.prefix}-alb-logs"
  force_destroy = true
}
