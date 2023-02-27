locals {
  public_subnet = [
  ]
  private_subnet = [
    {
      cidr              = cidrsubnet(local.vpc_cidr, 4, 14)
      availability_zone = "eu-west-2a"
      is_public         = false
      description       = "For DB services"
      }, {
      cidr              = cidrsubnet(local.vpc_cidr, 4, 14)
      availability_zone = "eu-west-2b"
      is_public         = false
      description       = "For DB services"
    }
  ]
}

locals {
  subnets     = concat(local.public_subnet, local.private_subnet)
  subnet_ids  = aws_subnet.db_subnets[*].id
  cidr_blocks = aws_subnet.db_subnets[*].cidr_block
}

resource "aws_subnet" "db_subnets" {
  count                   = length(local.subnets)
  cidr_block              = local.subnets[count.index].cidr
  vpc_id                  = local.vpc_id
  availability_zone       = local.subnets[count.index].availability_zone
  map_public_ip_on_launch = local.subnets[count.index].is_public

  tags = {
    Name        = "${local.prefix}-${local.subnets[count.index].is_public ? "public" : "private"}-${local.subnets[count.index].availability_zone}"
    Description = local.subnets[count.index].description
  }
}

