# AWS

The repo organizes various resources by directory. Create an HCP consul cluster and connect it to various resources (like ec2, eks, ecs, etc...) running in your own AWS VPC via Transit Gateway.

## EKS API was missing requird security group to route to EKS Pod.
(Worked) Deploy HCP Consul with Terraform
(Worked, But…) Connect an Amazon Transit GW to your Hashicorp Virtual Network
Converted this learn guide to use terraform
I used this guides inbound/outbound security rules: https://learn.hashicorp.com/tutorials/cloud/amazon-transit-gateway?in=consul/cloud-production#authorize-ingress-and-egress
These rules may only apply to the gateway, and probably not the correct source for all consul rules.  I thought the rules were good because they work with ec2 in the next step, but I think they are missing the ingress needed for EKS.
(Worked) Connect a Consul Client to HCP Consul
Converted this learn guide to use terraform
setup VPC with AWS VPC module
added 1 ec2 bastion to public subnet for future troubleshooting and to setup an example vm client
(Almost Worked) Connect an Elastic Kubernetes Service Cluster to HCP Consul
Converted this learn guide to use terraform
Setup EKS cluster with AWS EKS module
Setup consul secrets and helm chart to use terraform.
Helm deployment failed a lot. Had to work out chart name/version and security group rules to get this working.
(FAILED) Deployed Hashicups with kubectl following guide and this failed because EKS API didn’t have needed access to EKS pods.