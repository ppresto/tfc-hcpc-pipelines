variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "us-west-1"
}

variable "organization" { default = "my_org_name" }

# VPC
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.20.0.0/16"
}

# EC2 Variables
variable "ami_id" {
  description = "AMI ID to be used on all AWS EC2 Instances."
  type        = string
  default     = "ami-0747bdcabd34c712a" # Latest Ubuntu 18.04 LTS (HVM), SSD Volume Type
}

variable "use_latest_ami" {
  description = "Whether or not to use the hardcoded ami_id value or to grab the latest value from SSM parameter store."
  type        = bool
  default     = true
}

variable "ec2_key_pair_name" {
  description = "An existing EC2 key pair used to access the bastion server."
  type        = string
  default     = "ppresto-ptfe-dev-key"
}

# Allowed Traffic into the Bastion
variable "allowed_bastion_cidr_blocks" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to Everywhere."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_bastion_cidr_blocks_ipv6" {
  description = "List of CIDR blocks allowed to access your Bastion.  Defaults to none."
  type        = list(string)
  default     = []
}