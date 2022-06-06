#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/templates/${var.consul_template}/helm/helm-config.yaml")
  vars = {
    DATACENTER            = local.consul_datacenter
    RETRY_JOIN            = jsonencode(local.consul_retry_join)
    KUBE_API_URL          = data.terraform_remote_state.aws-eks.outputs.cluster_endpoint
    CONSUL_DNS_CLUSTER_IP = var.consul_dns_cluster_ip
  }
}

resource "helm_release" "consul" {
  name             = "consul"
  namespace        = var.namespace
  create_namespace = false
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "consul"
  version          = "0.33.0"

  values = [data.template_file.agent_config.rendered]
  set {
    name  = "global.image"
    value = "hashicorp/consul-enterprise:1.11.0-ent"
    #value = "hashicorp/consul:1.10.1"
  }
}

#
### Configure 3 Consul Secrets for the Helm Chart (aka: Agents)
#
resource "kubernetes_secret" "consul-ca-cert" {
  metadata {
    name      = "consul-ca-cert"
    namespace = var.namespace
  }
  data = {
    "tls.crt" = base64decode(data.terraform_remote_state.hcp_consul.outputs.consul_ca_file)
  }
}

resource "kubernetes_secret" "consul-gossip-key" {
  metadata {
    name      = "consul-gossip-key"
    namespace = var.namespace
  }
  data = {
    "key" = local.consul_config_file.encrypt
  }
}

resource "kubernetes_secret" "consul-bootstrap-token" {
  metadata {
    name      = "consul-bootstrap-token"
    namespace = var.namespace
  }
  data = {
    "token" = local.consul_acl_token
  }
}