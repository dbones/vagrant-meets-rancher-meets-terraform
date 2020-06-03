//https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
variable "nodes" {
    type = list(object({
        ip = string
        pem = string
        user = string
    }))
  
}

variable "hostname" {
  type = string
}

