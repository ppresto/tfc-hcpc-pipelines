data "kubectl_path_documents" "fake-service" {
  pattern = "${path.module}/templates/${var.consul_template}/*.yaml"
}
data "kubectl_path_documents" "consul-init" {
  pattern = "${path.module}/templates/${var.consul_template}/init-consul-config/*.yaml"
}

resource "kubectl_manifest" "consul-init" {
  for_each   = toset(data.kubectl_path_documents.consul-init.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.fake-service]
}
# Manually deploying before running this to show before consul picture
resource "kubectl_manifest" "fake-service" {
  for_each   = toset(data.kubectl_path_documents.fake-service.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}

data "kubernetes_service" "ingress" {
  metadata {
    name = "consul-ingress-gateway"
    namespace = var.namespace
  }
  depends_on = [kubectl_manifest.consul-init]
}