#
### Install Consul Client Agents into EKS using helm
#

data "template_file" "agent_config" {
  template = file("${path.module}/templates/fake-service/helm/helm-config.yaml")
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
resource "helm_release" "consul" {
  name             = "team1"
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
  depends_on = [kubernetes_namespace.create]
}

#resource "consul_acl_auth_method" "team1" {
#  name        = "team1-eks"
##  type        = "kubernetes"
#  description = "team1"
#
#  config_json = jsonencode({
#    Host              = local.eks_cluster_endpoint
#    CACert            = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
#    ServiceAccountJWT = nonsensitive(base64decode(data.aws_eks_cluster_auth.cluster.token))
#  })
#}

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