resource "null_resource" "rancher_installed" {

  provisioner "remote-exec" {
    inline = [ "curl --connect-timeout 5  --max-time 10  --retry 100  --retry-delay 0 --retry-max-time 40 --insecure 'https://localhost'"]
  }

  connection {
    type     = "ssh"
    user     = var.ssh.user
    private_key = file(var.ssh.private_key)
    host     = var.ssh.host
  }
}

//https://www.terraform.io/docs/providers/rancher2/index.html
provider "rancher2" {
  api_url   = var.url
  bootstrap = true
  insecure = true
  
}

resource "rancher2_bootstrap" "admin" {
  password = var.password
  depends_on = [ null_resource.rancher_installed ]
}


