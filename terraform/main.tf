# Debugging output
resource "null_resource" "terraform-debug" {
  provisioner "local-exec" {
    command = "echo $VARIABLE1 >> debug.txt ; echo $VARIABLE2 >> debug.txt"

    environment = {
        VARIABLE1 = jsonencode(local.public_key_list)
        VARIABLE1 = jsonencode(local.pairs)
    }
  }
}

module "wireguard" {
  source        = "github.com/josephramsay/terraform-aws-wireguard.git"
  ssh_key_id    = var.ssh-key
  vpc_id        = var.vpc-id
  subnet_ids    = flatten([var.public-subnet-cidr,var.private-subnet-cidr])
  use_eip       = var.eip-active
  eip_id        = "${aws_eip.wireguard.id}"
  wg_server_net = var.subnet-cidr # client IPs MUST exist in this net
  wg_client_public_keys = [
    { "192.168.2.2/32" = "QFX/DXxUv56mleCJbfYyhN/KnLCrgp7Fq2fyVOk/FWU=" }, # make sure these are correct
    { "192.168.2.3/32" = "+IEmKgaapYosHeehKW8MCcU65Tf5e4aXIvXGdcUlI0Q=" }, # wireguard is sensitive
    { "192.168.2.4/32" = "WO0tKrpUWlqbl/xWv6riJIXipiMfAEKi51qvHFUU30E=" }, # to bad configuration
  ]
  #local.pairs
}

/*
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-1"
  profile = "joer"
}
*/
# use a data object instead of a resource
data "aws_s3_bucket_object" "public_key_data" {
  bucket = "vibrant-dragon"
  key    = "config/vpn-pub.json"
}

locals {    
    public_key_list = jsondecode(data.aws_s3_bucket_object.public_key_data.body)
    pairs = [for item in local.public_key_list : 
      [for ip_key in item.keys: tostring(ip_key.ip)]
    ]

}

/*
resource "aws_iam_user" "user" {
    for_each = toset(local.k1)
    name = each.value
}
*/