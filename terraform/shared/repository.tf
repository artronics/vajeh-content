resource "aws_ecr_repository" "db_registry" {
  name = "${local.prefix}-db"
}

