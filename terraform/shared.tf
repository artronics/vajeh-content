data "terraform_remote_state" "vajeh-content-shared" {
  backend = "s3"
  config = {
    bucket = "${var.project}-shared-${local.account_name}-terraform-state"
    key    = "env://shared/state"
    region = "eu-west-2"
  }
}

locals {
  db_repository_name = data.terraform_remote_state.vajeh-content-shared.outputs.db_repository_name
  db_subnet_ids      = data.terraform_remote_state.vajeh-content-shared.outputs.db_subnet_ids
}
