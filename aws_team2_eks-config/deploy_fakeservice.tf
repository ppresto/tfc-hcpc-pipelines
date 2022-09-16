data "kubectl_path_documents" "fake-service" {
  pattern = "${path.module}/templates/${var.consul_template}/release-payments/*.yaml"
}
data "kubectl_path_documents" "consul-init" {
  pattern = "${path.module}/templates/${var.consul_template}/init-consul-config/*.yaml"
}

resource "kubectl_manifest" "consul-init" {
  for_each   = toset(data.kubectl_path_documents.consul-init.documents)
  yaml_body  = each.value
  depends_on = [helm_release.consul]
}

resource "kubectl_manifest" "fake-service" {
  for_each   = toset(data.kubectl_path_documents.fake-service.documents)
  yaml_body  = each.value
  depends_on = [kubectl_manifest.consul-init]
}