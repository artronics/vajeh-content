data "terraform_remote_state" "vajeh-infra" {
  backend = "s3"
  config = {
    bucket = "vajeh-infra-ptl-terraform-state"
    key    = "state"
    region = "eu-west-2"
  }
}

locals {
  vpc_id   = data.terraform_remote_state.vajeh-infra.outputs.vpc_id
  vpc_cidr = data.terraform_remote_state.vajeh-infra.outputs.vpc_cidr
}
