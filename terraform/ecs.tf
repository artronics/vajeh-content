resource "aws_ecs_cluster" "db_cluster" {
  name = "${local.prefix}-db"
}
