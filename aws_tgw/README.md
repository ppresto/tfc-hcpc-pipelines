# AWS VPC + Transit Gateway

Configuration in this directory creates the AWS VPC, Transit Gateway, TGW attachements and shares it with other AWS principals using [Resource Access Manager (RAM)](https://aws.amazon.com/ram/).  An SSH Bastion host is provisioned in a public subnet with external access and all security groups, routes, and services running to connect it to HCP Consul.

## Notes
An SSH Bastion host was created in the public subnet with rules allowing ssh to private subnets for troubleshooting.
* Update variable: ec2_key_pair_name with your key pair name
* Update variable: allowed_bastion_cidr_blocks to your public IP for better security

If you have your aws keypair setup your ssh agent (-A) and the bastion_ip you can ssh to it.
```
ssh -A ubuntu@${bastion_ip}
```
## Usage

To run this example you need to execute:

```bash
$ cd ./aws_network
$ terraform init
$ terraform plan
$ terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.12.26 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 2.24 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 2.24 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_tgw"></a> [tgw](#module\_tgw) | ../../ | n/a |
| <a name="module_vpc"></a> [vpc1](#module\_vpc1) | terraform-aws-modules/vpc/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_subnet_ids.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet_ids) | data source |
| [aws_vpc.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_transit_gateway_arn"></a> [ec2\_transit\_gateway\_arn](#output\_ec2\_transit\_gateway\_arn) | EC2 Transit Gateway Amazon Resource Name (ARN) |
| <a name="output_ec2_transit_gateway_association_default_route_table_id"></a> [ec2\_transit\_gateway\_association\_default\_route\_table\_id](#output\_ec2\_transit\_gateway\_association\_default\_route\_table\_id) | Identifier of the default association route table |
| <a name="output_ec2_transit_gateway_id"></a> [ec2\_transit\_gateway\_id](#output\_ec2\_transit\_gateway\_id) | EC2 Transit Gateway identifier |
| <a name="output_ec2_transit_gateway_owner_id"></a> [ec2\_transit\_gateway\_owner\_id](#output\_ec2\_transit\_gateway\_owner\_id) | Identifier of the AWS account that owns the EC2 Transit Gateway |
| <a name="output_ec2_transit_gateway_propagation_default_route_table_id"></a> [ec2\_transit\_gateway\_propagation\_default\_route\_table\_id](#output\_ec2\_transit\_gateway\_propagation\_default\_route\_table\_id) | Identifier of the default propagation route table |
| <a name="output_ec2_transit_gateway_route_ids"></a> [ec2\_transit\_gateway\_route\_ids](#output\_ec2\_transit\_gateway\_route\_ids) | List of EC2 Transit Gateway Route Table identifier combined with destination |
| <a name="output_ec2_transit_gateway_route_table_association"></a> [ec2\_transit\_gateway\_route\_table\_association](#output\_ec2\_transit\_gateway\_route\_table\_association) | Map of EC2 Transit Gateway Route Table Association attributes |
| <a name="output_ec2_transit_gateway_route_table_association_ids"></a> [ec2\_transit\_gateway\_route\_table\_association\_ids](#output\_ec2\_transit\_gateway\_route\_table\_association\_ids) | List of EC2 Transit Gateway Route Table Association identifiers |
| <a name="output_ec2_transit_gateway_route_table_default_association_route_table"></a> [ec2\_transit\_gateway\_route\_table\_default\_association\_route\_table](#output\_ec2\_transit\_gateway\_route\_table\_default\_association\_route\_table) | Boolean whether this is the default association route table for the EC2 Transit Gateway |
| <a name="output_ec2_transit_gateway_route_table_default_propagation_route_table"></a> [ec2\_transit\_gateway\_route\_table\_default\_propagation\_route\_table](#output\_ec2\_transit\_gateway\_route\_table\_default\_propagation\_route\_table) | Boolean whether this is the default propagation route table for the EC2 Transit Gateway |
| <a name="output_ec2_transit_gateway_route_table_id"></a> [ec2\_transit\_gateway\_route\_table\_id](#output\_ec2\_transit\_gateway\_route\_table\_id) | EC2 Transit Gateway Route Table identifier |
| <a name="output_ec2_transit_gateway_route_table_propagation"></a> [ec2\_transit\_gateway\_route\_table\_propagation](#output\_ec2\_transit\_gateway\_route\_table\_propagation) | Map of EC2 Transit Gateway Route Table Propagation attributes |
| <a name="output_ec2_transit_gateway_route_table_propagation_ids"></a> [ec2\_transit\_gateway\_route\_table\_propagation\_ids](#output\_ec2\_transit\_gateway\_route\_table\_propagation\_ids) | List of EC2 Transit Gateway Route Table Propagation identifiers |
| <a name="output_ec2_transit_gateway_vpc_attachment"></a> [ec2\_transit\_gateway\_vpc\_attachment](#output\_ec2\_transit\_gateway\_vpc\_attachment) | Map of EC2 Transit Gateway VPC Attachment attributes |
| <a name="output_ec2_transit_gateway_vpc_attachment_ids"></a> [ec2\_transit\_gateway\_vpc\_attachment\_ids](#output\_ec2\_transit\_gateway\_vpc\_attachment\_ids) | List of EC2 Transit Gateway VPC Attachment identifiers |
| <a name="output_ram_principal_association_id"></a> [ram\_principal\_association\_id](#output\_ram\_principal\_association\_id) | The Amazon Resource Name (ARN) of the Resource Share and the principal, separated by a comma |
| <a name="output_ram_resource_share_id"></a> [ram\_resource\_share\_id](#output\_ram\_resource\_share\_id) | The Amazon Resource Name (ARN) of the resource share |

# Troubleshooting

## AWS user_data
When a user data script is processed, it is copied to and run from /var/lib/cloud/instances/instance-id/. The script is not deleted after it is run and can be found in this directory with the name user-data.txt.  
```
sudo cat /var/lib/cloud/instance/user-data.txt
```
The cloud-init log captures console output of the user-data script run.
```
sudo cat /var/log/cloud-init-output.log
```

## systemctl consul.service
This repo creates the systemd start script located at `/etc/systemd/system/consul.service`.  This scripts requires:
*  /opt/consul to store data.
*  /etc/consul.d/certs - ca.pem from HCP
*  /etc/consul.d/ - HCP default configs and an ACL token

To stop, start, and get the status of the service
```
systemctl stop consul.service
systemctl start consul.service
systemctl status consul.service
```

To investigate systemd errors starting consul use `journalctl`
```
journalctl -u consul.service
```