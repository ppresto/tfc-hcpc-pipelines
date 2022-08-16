# Admin Partitions and Namespaces
resource "consul_admin_partition" "qa" {
  name        = "qa"
  description = "Partition for QA Environment"
}
resource "consul_namespace" "qa-app-api" {
  name        = "api"
  description = "API App Team"
  partition   = consul_admin_partition.qa.name
  meta = {
    foo = "bar"
  }
}
resource "consul_namespace" "default-app-api" {
  name        = "api"
  description = "API App Team"
  partition   = "default"

  meta = {
    foo = "bar"
  }
}

# Service Policies and Tokens (api)
resource "consul_acl_policy" "api-service" {
  name        = "api-service"
  datacenters = ["dc1"]
  rules       = <<-RULE
    service "api*" {
      policy = "write"
      intenstions = "read"
    }

    service "api-sidecar-proxy" {
      policy = "write"
    }

    service_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }
  RULE
}

# Create Default DNS Lookup policy and attach to anonymous.
resource "consul_acl_policy" "dns-request" {
  name  = "dns-request-policy"
  rules = <<-RULE
    node_prefix "" {
      policy = "read"
    }
    service_prefix "" {
      policy = "read"
    }
    # only needed if using prepared queries
    query_prefix "" {
      policy = "read"
    }
    RULE
}

resource "consul_acl_token_policy_attachment" "attachment" {
    token_id = "00000000-0000-0000-0000-000000000002"
    policy   = "${consul_acl_policy.dns-request.name}"
}

resource "consul_acl_token" "api-service" {
  description = "my api service token"
  policies    = ["${consul_acl_policy.api-service.name}"]
  local       = true
}
data "consul_acl_token_secret_id" "api-service" {
  accessor_id = consul_acl_token.api-service.id
  #pgp_key     = "keybase:my_username"
}
output "consul_service_api_token" {
  value = nonsensitive(data.consul_acl_token_secret_id.api-service.secret_id)
}