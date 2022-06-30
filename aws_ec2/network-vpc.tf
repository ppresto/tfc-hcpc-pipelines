# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  name    = "${var.prefix}-${var.region}-vpc2"
  cidr    = var.vpc_cidr_block
  #azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  azs                      = data.aws_availability_zones.available.names
  private_subnets          = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  public_subnets           = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
  enable_nat_gateway       = true
  single_nat_gateway       = true
  enable_dns_hostnames     = true
  enable_ipv6              = false
  default_route_table_name = "${var.prefix}-vpc2-default-rt"
  tags = {
    Terraform  = "true"
    Owner      = "${var.prefix}"
    transit_gw = "true"
  }
  private_subnet_tags = {
    Tier = "Private"
  }
  public_subnet_tags = {
    Tier = "Public"
  }
  default_route_table_tags = {
    Name = "${var.prefix}-vpc2-default-rt"
  }
  private_route_table_tags = {
    Name = "${var.prefix}-vpc2-private-rt"
  }
  public_route_table_tags = {
    Name = "${var.prefix}-vpc2-public-rt"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "example" {
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = data.terraform_remote_state.aws_usw_dev_tgw.outputs.ec2_transit_gateway_id
  vpc_id             = module.vpc.vpc_id
}
resource "aws_route_table" "example" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = var.vpc_cidr_block
    transit_gateway_id = data.terraform_remote_state.aws_usw_dev_tgw.outputs.ec2_transit_gateway_id
  }
  tags = {
    Name = "${var.prefix}-vpc2-rt"
  }
}