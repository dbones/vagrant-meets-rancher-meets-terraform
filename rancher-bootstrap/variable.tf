variable "password" {
  type = string
}

variable "url" {
  type = string
}

variable "ssh" {
  type = object({
    user = string
    private_key = string
    host = string
  })
  
}