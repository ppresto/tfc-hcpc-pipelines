#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/templates/helm/helm-config.yaml")
  vars = {
    NAME_PREFIX           = var.helm_release_name
    DATACENTER            = local.consul_datacenter
    RETRY_JOIN            = jsonencode(local.consul_retry_join)
    KUBE_API_URL          = local.eks_cluster_endpoint
    CONSUL_DNS_CLUSTER_IP = var.consul_dns_cluster_ip
  }
}

resource "kubernetes_namespace" "create" {
  metadata {
    labels = {
      service = var.namespace
    }
    name = var.namespace
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
    "tls.crt" = base64decode(local.consul_client_ca)
  }
  depends_on = [kubernetes_namespace.create]
}

resource "kubernetes_secret" "consul-gossip-key" {
  metadata {
    name      = "consul-gossip-key"
    namespace = var.namespace
  }
  data = {
    "key" = local.consul_gossip_key
  }
  depends_on = [kubernetes_namespace.create]
}

resource "kubernetes_secret" "consul-bootstrap-token" {
  metadata {
    name      = "consul-bootstrap-token"
    namespace = var.namespace
  }
  data = {
    "token" = local.consul_root_token
  }
  depends_on = [kubernetes_namespace.create]
}