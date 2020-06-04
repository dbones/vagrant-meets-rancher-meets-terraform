provider "rke" {
  debug = false
}

locals {
  kube_config_path = "${path.module}/kube-config.yaml"
}

resource rke_cluster "cluster" {

  dynamic "nodes" {
    for_each = [for n in var.nodes : {
      ip   = n.ip
      pem  = n.pem
      user = n.user
    }]

    content {
      address = nodes.value.ip
      ssh_key = file(nodes.value.pem)
      user    = nodes.value.user
      role    = ["controlplane", "worker", "etcd"]

    }
  }

}

resource "null_resource" "rke_up" {
  count = length(var.nodes)
  provisioner "remote-exec" {
    inline = [
      "curl --connect-timeout 5  --max-time 10  --retry 25  --retry-delay 0 --retry-max-time 40 --insecure 'https://${var.nodes[0].ip}:6443'",
    ]
  }

  connection {
    type     = "ssh"
    user     = var.nodes[count.index].user
    host     = var.nodes[count.index].ip
    private_key  = file(var.nodes[count.index].pem)
  }

  depends_on = [
    rke_cluster.cluster
  ]
}


resource "local_file" "kube_cluster_yaml" {
  filename = local.kube_config_path
  content  = rke_cluster.cluster.kube_config_yaml
}

//setup helm to install rancher
provider "helm" {
  kubernetes {
    host             = rke_cluster.cluster.api_server_url
    load_config_file = "false"

    client_certificate     = rke_cluster.cluster.client_cert
    client_key             = rke_cluster.cluster.client_key
    cluster_ca_certificate = rke_cluster.cluster.ca_crt
  }
}

provider "kubernetes" {
  host             = rke_cluster.cluster.api_server_url
  load_config_file = "false"

  client_certificate     = rke_cluster.cluster.client_cert
  client_key             = rke_cluster.cluster.client_key
  cluster_ca_certificate = rke_cluster.cluster.ca_crt
}



//cert-manager
resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }

  depends_on = [
    null_resource.rke_up
  ]
}

resource "null_resource" "cert_manager" {
  provisioner "local-exec" {
    when    = "create"
    command = "kubectl apply --kubeconfig=${local.kube_config_path} -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl delete --kubeconfig=${local.kube_config_path} -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml"
  }

  depends_on = [
    kubernetes_namespace.cert_manager,
    local_file.kube_cluster_yaml
  ]
}

data "helm_repository" "jetstack" {
  name = "jetstack"
  url  = "https://charts.jetstack.io"
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = data.helm_repository.jetstack.metadata[0].name
  chart      = "jetstack/cert-manager"
  version    = "v0.12.0"
  namespace  = "cert-manager"
  wait       = true


  depends_on = [
    null_resource.cert_manager,
    data.helm_repository.jetstack
  ]
}


//Rancher
resource "kubernetes_namespace" "cattle_system" {
  metadata {
    name = "cattle-system"
  }
}


data "helm_repository" "rancher" {
  name = "rancher-latest"
  url  = "https://releases.rancher.com/server-charts/latest"
}


resource "helm_release" "rancher" {
  name       = "rancher"
  repository = data.helm_repository.rancher.metadata[0].name
  chart      = "rancher-latest/rancher"
  namespace  = "cattle-system"
  wait       = true

  set {
    name  = "hostname"
    value = var.hostname
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_namespace.cattle_system,
    data.helm_repository.rancher
  ]
}