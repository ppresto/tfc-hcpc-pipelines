/*
Set the following Env variables to connect to HCP
  variable "HCP_CLIENT_SECRET"
  variable "HCP_CLIENT_ID"
*/

variable "hvn_id" {
  description = "The ID of the HCP HVN."
  type        = string
  default     = "learn-hvn"
}
variable "hvn_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "172.25.16.0/20"
}
variable "cluster_id" {
  description = "The ID of the HCP Consul cluster."
  type        = string
  default     = "learn-hcp-consul"
}
variable "region" {
  description = "The region of the HCP HVN and Consul cluster."
  type        = string
  default     = "us-west-2"
}
variable "cloud_provider" {
  description = "The cloud provider of the HCP HVN and Consul cluster."
  type        = string
  default     = "aws"
}

# VPC
variable "vpc_cidr_block" {
  description = "VPC CIDR Block Range"
  type        = string
  default     = "10.20.0.0/16"
}
