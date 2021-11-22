variable "namespace" {
  type = string
  default = "vp-wgvpn"
}

variable "cidr" {
  type = string
  default = "192.168.1.0/24"
}

variable "public-subnet-cidr" {
  type  = list(string)
  default = ["172.16.16.64/18","172.16.16.128/18"]
}

variable "private-subnet-cidr" {
  type  = list(string)
  default = ["172.16.16.192/18","172.16.16.254/18"]
}

data "aws_availability_zones" "available" {
  state = "available"
}