provider "aws" {
  region = var.region
}
# data source for current (working) aws region
data "aws_region" "current" {}

# data source for VPC id for the VPC being used
data "aws_vpc" "vpc" {
  default = true
}

# data source for subnet ids in VPC
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.vpc.id
}

# data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  name    = "vpc-ipv4-presto-1"
  cidr    = var.vpc_cidr_block
  #azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  azs                      = data.aws_availability_zones.available.names
  private_subnets          = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets           = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
  enable_nat_gateway       = true
  single_nat_gateway       = true
  enable_dns_hostnames     = true
  enable_ipv6              = false
  default_route_table_name = "presto-1-default-rt"
  tags = {
    Terraform  = "true"
    Owner      = "presto"
    transit_gw = "true"
  }
  private_subnet_tags = {
    Tier = "Private"
  }
  public_subnet_tags = {
    Tier = "Public"
  }
  default_route_table_tags = {
    Name = "presto-1-default-rt"
  }
  private_route_table_tags = {
    Name = "presto-1-private-rt"
  }
  public_route_table_tags = {
    Name = "presto-1-public-rt"
  }
}

