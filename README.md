# hcpc-vpc-ec2-eks
[HCP Consul](https://cloud.hashicorp.com/products/consul) enables platform operators to quickly deploy a fully managed, secure-by-default service mesh, helping developers discover and securely connect any application on any runtime, including Kubernetes, Nomad, Amazon ECS, EC2, and more.

To get started with HCP Consul follow this [HCP Consul Getting Started guide](https://learn.hashicorp.com/tutorials/cloud/get-started-consul#prerequisites).  It will walk you through your free account creation and setting up your Consul Cluster.  It will take you step by step through the process for onboarding platforms like Kubernetes or VMs and eventually registering the services on those platforms.

The purpose of this tutorial is to use Terraform for IaC as we dive a little deeper into each stage of our journey to implement HCP Consul the Hashicorp hosted Service Mesh.

PreReqs:
* [Create HCP Account](https://portal.cloud.hashicorp.com/?utm_source=learn)
* Create HCP IAM Service principal and key with role: `Contributor`
* Create AWS IAM Credentials with privilages to build: `vpc, sg, tgw, eks, ec2`

## Provision the Plumbing - HCP, AWS VPC and Transit GW
This tutorial can be ran from the CLI using OSS terraform.  Just update the data.tf files to reference local state files and script the TFCB steps below.  I prefer using Terraform Cloud for Business (TFCB).  Like OSS it uses the same terraform binary.  Unlike OSS it centralizes and automates the admin of all your infra provisioning processes supporting many additional workflows out of the box.  I'll be using the VCS workflow which applies changes when the repo has a new commit.  TFCB supports RBAC across people and teams to enable collaboration and securely store or share sensitive data across pipelines.  We will leverage this capability to securely share tf outputs from different state files when configuring our remote ec2 and eks agents.

### Setup TFCB
1. Go to `tfcb_workspaces/scripts`
* read the TFE_Workspace_README.md and follow all the steps to setup your terminal environment.
* update `addAdmin_workspace.sh` with your TFCB, Github, and Env information
* successfully create your TFCB workspace

1. 