#
### Create K8s Namespace if it doesn't exist
#

resource "kubernetes_namespace" "create" {
  metadata {
    labels = {
      service = "consul"
    }
    name = "consul"
  }
}