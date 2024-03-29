# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"
  name    = "${var.prefix}-${var.region}-vpc3"
  cidr    = "10.15.0.0/16"
  #azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  azs                      = data.aws_availability_zones.available.names
  private_subnets          = ["10.15.1.0/24", "10.15.2.0/24", "10.15.3.0/24"]
  public_subnets           = ["10.15.11.0/24", "10.15.12.0/24", "10.15.13.0/24"]
  enable_nat_gateway       = true
  single_nat_gateway       = true
  enable_dns_hostnames     = true
  enable_ipv6              = false
  default_route_table_name = "${var.prefix}-vpc3-default-rt"
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
    Name = "${var.prefix}-vpc3-default-rt"
  }
  private_route_table_tags = {
    Name = "${var.prefix}-vpc3-private-rt"
  }
  public_route_table_tags = {
    Name = "${var.prefix}-vpc3-public-rt"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "vpc3" {
  subnet_ids         = module.vpc.private_subnets
  transit_gateway_id = data.terraform_remote_state.aws_usw_dev_tgw.outputs.ec2_transit_gateway_id
  vpc_id             = module.vpc.vpc_id
  tags = {
    project = "${var.region}-vpc3-tgw"
  }
}

# vpc_main_route_table_id
resource "aws_route" "privateToHcp" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = data.terraform_remote_state.hcp_consul.outputs.hvn_cidr_block
  transit_gateway_id     = data.terraform_remote_state.aws_usw_dev_tgw.outputs.ec2_transit_gateway_id
}
resource "aws_route" "privateToAllInt" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/10"
  transit_gateway_id     = data.terraform_remote_state.aws_usw_dev_tgw.outputs.ec2_transit_gateway_id
}