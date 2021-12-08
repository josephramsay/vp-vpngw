variable "namespace" {
  type = string
  default = "vp-wgvpn"
}

variable "ssh-key" {
  type = string
  default = "id_vp_wgvpn_rsa"
}

variable "vpc-id" {
  type = string
  default = "vp-wgvpn-vpc"
}
variable "subnet-cidr" {
  type = string
  default = "172.24.0.0/16"
}

variable "eip-active" {
  type = bool
  default = true
}

variable "public-subnet-cidr" {
  type  = list(string)
  default = ["172.24.0.0/18","172.24.128.0/18"]
}

variable "private-subnet-cidr" {
  type  = list(string)
  default = ["172.24.64.0/18","172.24.192.0/18"]
}

variable "wg_server_private_key_param" {
  default = "QFX/DXxUv56mleCJbfYyhN/KnLCrgp7Fq2fgVOk/FWU="
  description = "The SSM parameter containing the WG server private key."
}
variable "wg_server_port" {
  type = number
  default = 8080
}
variable "wg_server_interface" {
  type = string
  default = "wg0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

