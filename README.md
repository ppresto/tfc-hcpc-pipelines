# hcpc-vpc-ec2-eks
[HCP Consul](https://cloud.hashicorp.com/products/consul) enables platform operators to quickly deploy a fully managed, secure-by-default service mesh, helping developers discover and securely connect any application on any runtime, including Kubernetes, Nomad, Amazon ECS, EC2, and more.

To get started with HCP Consul follow this [HCP Consul Getting Started guide](https://learn.hashicorp.com/tutorials/cloud/get-started-consul#prerequisites).  It will walk you through your free account creation and setting up your Consul Cluster.  It will take you step by step through the process for onboarding platforms like Kubernetes or VMs and eventually registering the services on those platforms.

The purpose of this tutorial is to use Terraform for IaC as we dive a little deeper into each stage of our journey to implement HCP Consul the Hashicorp hosted Service Mesh.

PreReqs:
* [Create TFC Account](https://app.terraform.io/signup)
* [Create HCP Account](https://portal.cloud.hashicorp.com/?utm_source=learn)
* Create HCP IAM Service principal and key with role: `Contributor`
* Obtain AWS IAM Credentials with privilages to build: `vpc, sg, tgw, eks, ec2`

## Provision the Plumbing - HCP, AWS VPC and Transit GW
This tutorial will use Terraform Cloud (TFC) because its free to individuals and offers better security and centralized administration.  We will be using the VCS workflow which applies changes when the configured github repo:branch has merged a new commit.  This enforces using VCS for all changes.  TFCB has a private module registry with support for SSO, and RBAC to enable collaboration and self service across teams which is great for larger Orgs.  TFC uses Vault's AES 256 bit encryption under the hood to securely store and share sensitive data across any pipeline.  We will leverage these capability to securely share terraform outputs from different state files when configuring things like our transit gateway, ec2, and eks consul agents.

### Setup TFCB
This setup can be done manually through the UI, but we are going to use the TFC API to setup our first workspace.  This will be our administrative workspace we use to store sensitive variables and build and manage our other child workspaces using Terraform (TFE provider).

Go to `tfcb_workspaces/scripts`
* read `TFE_Workspace_README.md` and follow all the steps to setup your terminal environment.
* run `addAdmin_workspace.sh` to successfully create the admin-tfc-workspace

Create workspaces for each of the infrastructure components we need to provision in the environment.
* Go to TFCB -> admin-tfc-workspace -> Actions -> Start new run -> Start run

Now you should have a few more workspaces created.  The `hcp_consul` workspace was set with queue_all_runs=true so it will attempt to run terraform plan/apply immediately.  This workspace must have AWS credentials to run.  Verify it ran successfully.  If necessary troubleshoot any issues and rerun until you have HCP setup and a working VPC.