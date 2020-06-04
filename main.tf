locals {
  vagrant_path = "D:/virtual/full-rancher/.vagrant/machines"
  rancher_ip   = "172.19.8.150"
  rancher_hostname  = "rancher" 
  rancher_url = "https://${local.rancher_hostname}"

  username = "dave"

  node_ip = "172.19.8.20"
  node_count = 3
}

resource "random_password" "admin_password" {
  length = 16
  special = true
  override_special = "_%@"
}

module "rancher_server" {
  source = "./rancher-server"

  hostname = local.rancher_hostname

  nodes = [
    {
      ip   = local.rancher_ip
      user = "vagrant"
      pem  = "${local.vagrant_path}/rancher-01/virtualbox/private_key"
    }
  ]
}


module "rancher_bootstrap" {
  source = "./rancher-bootstrap"
  password = random_password.admin_password.result
  url = module.rancher_server.hostname

  ssh = {
    user = "vagrant"
    host = local.rancher_ip
    private_key = "${local.vagrant_path}/rancher-01/virtualbox/private_key"
  }
}

module "rancher_configuration" {
  source = "./rancher-configuration"

  url = local.rancher_url
  token = module.rancher_bootstrap.token
  username = local.username
  
}


output "token" {
  value = module.rancher_configuration.token
}

resource "null_resource" "register_cluster_nodes" {
  count = local.node_count
  provisioner "remote-exec" {
    inline = [
      "echo '${local.rancher_ip} rancher' | sudo tee -a /etc/hosts",
      "${module.rancher_configuration.token} --internal-address ${local.node_ip}${count.index+1} --address ${local.node_ip}${count.index+1} --etcd --controlplane --worker"
    ]
  }

  connection {
    type     = "ssh"
    user     = "vagrant"
    host     =  "${local.node_ip}${count.index+1}"
    private_key  = file("${local.vagrant_path}/node-0${count.index+1}/virtualbox/private_key")
  }

  depends_on = [
    module.rancher_configuration.token
  ]
}