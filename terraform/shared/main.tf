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
  workspace = "shared"
  prefix    = var.project
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Project   = var.project
      Workspace = local.workspace
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
      Workspace = local.workspace
      Tier      = local.tier
    }
  }
}
