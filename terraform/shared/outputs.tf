output "db_repository_name" {
  value = aws_ecr_repository.db_registry.name
}

output "db_subnet_ids" {
  value = local.subnet_ids
}
