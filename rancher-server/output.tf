output "config" {
  value =  rke_cluster.cluster.kube_config_yaml
}

output "hostname" {
  value = "https://${var.hostname}"
  depends_on = [helm_release.rancher]
}
