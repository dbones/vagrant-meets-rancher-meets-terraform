provider "rancher2" {
  api_url   = var.url
  token_key = var.token
  insecure  = true
}

locals {
  token = rancher2_cluster.dev_cluster.cluster_registration_token[0]
}

resource "rancher2_user" "default_user" {
  name     = var.username
  username = var.username
  password = "changeme"
  enabled  = true
}

resource "rancher2_global_role_binding" "default_user_role" {
  name           = "admin"
  global_role_id = "admin"
  user_id        = rancher2_user.default_user.id
}

resource "rancher2_cluster" "dev_cluster" {
  name        = "development"
  description = "Foo rancher2 custom cluster"
  rke_config {
    network {
      plugin = "canal"
    }
    services {
      etcd {
        creation  = "6h"
        retention = "24h"
      }
      kube_api {
        audit_log {
          enabled = true
          configuration {
            max_age    = 5
            max_backup = 5
            max_size   = 100
            path       = "-"
            format     = "json"
            policy     = file("${path.module}/auditlog_policy.yaml")
          }
        }
      }
    }
  }
}

resource "local_file" "kube_file" {
  content  = rancher2_cluster.dev_cluster.kube_config
  filename = "${path.module}/kube-config.txt"
}