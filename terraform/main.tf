# Resource, Wireguard Repo
resource "aws_eip" "wireguard" {
  vpc = true
  tags = {
    Name = "wireguard"
  }
}

# VPC
resource "aws_vpc" "vp-wgvpn-vpc" {
  cidr_block                       = var.cidr
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.namespace
    Namespace = var.namespace
  }
}

# Public Subnet
resource "aws_subnet" "vp-wgvpn-public-subnet" {
  count                   = 3
  cidr_block              = tolist(var.public-subnet-cidr)[count.index]
  vpc_id                  = aws_vpc.vp-wgvpn-vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.namespace}-public-subnet-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
    Namespace = var.namespace
  }

  depends_on = [aws_vpc.vp-wgvpn-vpc]
}

# Private Subnet
resource "aws_subnet" "vp-wgvpn-private-subnet" {
  count             = 3
  cidr_block        = tolist(var.private-subnet-cidr)[count.index]
  vpc_id            = aws_vpc.vp-wgvpn-vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.namespace}-private-subnet-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
    Namespace = var.namespace
  }

  depends_on = [aws_vpc.vp-wgvpn-vpc]
}

# Internet Gateway
resource "aws_internet_gateway" "vp-wgvpn-internet-gateway" {
  vpc_id = aws_vpc.vp-wgvpn-vpc.id

  tags = {
    Name = "${var.namespace}-internet-gateway"
    Namespace = var.namespace
  }

  depends_on = [aws_vpc.vp-wgvpn-vpc]
}

# Elastic IP
resource "aws_eip" "vp-wgvpn-elastic-ip" {
  count = 3
  vpc   = true

  tags = {
    Name = "vp-wgvpn-elastic-ip-${count.index + 1}"
    Namespace = var.namespace
  }

  depends_on = [aws_internet_gateway.vp-wgvpn-internet-gateway]
}

# NAT Gateway
resource "aws_nat_gateway" "vp-wgvpn-nat-gateway" {
  count         = 3
  allocation_id = aws_eip.vp-wgvpn-elastic-ip[count.index].id
  subnet_id     = aws_subnet.vp-wgvpn-public-subnet[count.index].id

  tags = {
    Name = "${var.namespace}-nat-gateway-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
    Namespace = var.namespace
  }

  depends_on = [aws_internet_gateway.vp-wgvpn-internet-gateway]
}


# Route Table for Public Routes
resource "aws_route_table" "vp-wgvpn-public-route-table" {
  vpc_id = aws_vpc.vp-wgvpn-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vp-wgvpn-internet-gateway.id
  }

  tags = {
    Name = "${var.namespace}-public-route-table"
    Namespace = var.namespace
  }

  depends_on = [aws_internet_gateway.vp-wgvpn-internet-gateway]
}

# Route Table Association - Public Routes
resource "aws_route_table_association" "vp-wgvpn-route-table-association-public-route" {
  count          = 3
  route_table_id = aws_route_table.vp-wgvpn-public-route-table.id
  subnet_id      = aws_subnet.vp-wgvpn-public-subnet[count.index].id

  depends_on = [aws_subnet.vp-wgvpn-public-subnet,  aws_route_table.vp-wgvpn-public-route-table]
}

# Route Table for Private Routes
resource "aws_route_table" "vp-wgvpn-private-route-table" {
  count  = 3
  vpc_id = aws_vpc.vp-wgvpn-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.vp-wgvpn-nat-gateway[count.index].id
  }

  tags = {
    Name = "${var.namespace}-private-route-table-${count.index + 1}"
    AZ   = data.aws_availability_zones.available.names[count.index]
    Namespace = var.namespace
  }

  depends_on = [aws_nat_gateway.vp-wgvpn-nat-gateway]
}

# Route Table Association - Private Routes
resource "aws_route_table_association" "vp-wgvpn-route-table-association-private-route" {
  count          = 3
  route_table_id = aws_route_table.vp-wgvpn-private-route-table[count.index].id
  subnet_id      = aws_subnet.vp-wgvpn-private-subnet[count.index].id

  depends_on = [aws_subnet.vp-wgvpn-private-subnet, aws_route_table.vp-wgvpn-private-route-table]
}

module "wireguard" {
  source        = "github.com/josephramsay/terraform-aws-wireguard.git"
  ssh_key_id    = "ssh-key-id-0987654"
  vpc_id        = "vp-wgvpn-vpc"
  subnet_ids    = ["subnet-01234567"]
  use_eip       = true
  eip_id        = "${aws_eip.wireguard.id}"
  wg_server_net = "192.168.2.1/24" # client IPs MUST exist in this net
  wg_client_public_keys = [
    { "192.168.2.2/32" = "QFX/DXxUv56mleCJbfYyhN/KnLCrgp7Fq2fyVOk/FWU=" }, # make sure these are correct
    { "192.168.2.3/32" = "+IEmKgaapYosHeehKW8MCcU65Tf5e4aXIvXGdcUlI0Q=" }, # wireguard is sensitive
    { "192.168.2.4/32" = "WO0tKrpUWlqbl/xWv6riJIXipiMfAEKi51qvHFUU30E=" }, # to bad configuration
  ]
}
