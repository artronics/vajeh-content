terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4"
    }
  }

  backend "s3" {
    key    = "state"
    region = "eu-west-2"
  }
}

locals {
  tier = "service"
}

locals {
  workspace     = terraform.workspace
  account_name  = local.workspace == "prod" ? "prod" : "ptl"
  prefix        = "${var.project}-${local.workspace}"
  secret_prefix = "vajeh/${local.tier}/${local.account_name}"
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project   = var.project
      Workspace = var.workspace_tag
      Tier      = local.tier
    }
  }
}

provider "aws" {
  alias  = "acm_provider"
  region = "us-east-1"
  default_tags {
    tags = {
      Project   = var.project
      Workspace = var.workspace_tag
      Tier      = local.tier
    }
  }
}
