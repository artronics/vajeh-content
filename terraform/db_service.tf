locals {
  db_service_name = "${local.prefix}-db"
  db_image_tag    = local.workspace
  db_port         = 9000
}

data "aws_ecr_repository" "db_repository" {
  name = local.db_repository_name
}

data "aws_subnet" "db_subnet" {
  count = length(local.db_subnet_ids)
  id    = local.db_subnet_ids[count.index]
}

resource "aws_ecs_service" "db_service" {
  name             = local.db_service_name
  cluster          = aws_ecs_cluster.db_cluster.id
  task_definition  = aws_ecs_task_definition.db_task.arn
  platform_version = "1.4.0"
  # 1.3.0 doesn't need a vpc_endpoint to *.ecr.api see:https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
  desired_count                      = 1
  launch_type                        = "FARGATE"
  force_new_deployment               = true
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  network_configuration {
    security_groups  = [aws_security_group.service_security_group.id]
    subnets          = local.db_subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_tg_arn
    container_name   = local.db_service_name
    container_port   = local.db_port
  }
}

resource "aws_security_group" "service_security_group" {
  name   = local.db_service_name
  vpc_id = local.vpc_id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = local.db_port
    to_port     = local.db_port
    cidr_blocks = data.aws_subnet.db_subnet.*.cidr_block
  }
}

resource "aws_ecs_task_definition" "db_task" {
  family       = local.db_service_name
  network_mode = "awsvpc"
  // ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services.
  task_role_arn = aws_iam_role.task_role.arn
  //ARN of the task execution role that the Amazon ECS container agent and the Docker daemon can assume.
  execution_role_arn       = aws_iam_role.db_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  container_definitions = jsonencode([
    {
      name      = local.db_service_name
      image     = "${data.aws_ecr_repository.db_repository.repository_url}:${local.db_image_tag}"
      essential = true

      portMappings = [
        {
          containerPort = local.db_port
          hostPort      = local.db_port
        }
      ]

      environment : [
        { "name" : "PORT", "value" : tostring(local.db_port) }
      ],
      #      logConfiguration : {
      #        "logDriver" : "awslogs",
      #        "options" : {
      #          "awslogs-create-group" : "true",
      #          "awslogs-group" : aws_cloudwatch_log_group.container_log_group.name
      #          "awslogs-region" : "eu-west-2",
      #          // TODO: Fargate creates it's own stream. Do we need to create our own? -> set awslogs-create-group to false and see if we can use our own stream which has retention
      #          "awslogs-stream-prefix" : aws_cloudwatch_log_stream.container_log_stream.name
      #        }
      #      }
    }
  ])
}

resource "aws_iam_role" "task_role" {
  name               = "${local.db_service_name}-task-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role" "db_task_execution_role" {
  name               = "${local.db_service_name}-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "db_main_ecs_tasks" {
  name = "${local.db_service_name}-ecs-tasks"
  role = aws_iam_role.db_task_execution_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": ["*"]
        },
        {
            "Effect": "Allow",
            "Resource": [
              "*"
            ],
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:DescribeLogStreams"
            ]
        }
    ]

}
EOF
}
