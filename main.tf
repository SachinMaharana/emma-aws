data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}


locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}

data "aws_route53_zone" "selected" {
  name         = "${var.hosted_zone}"
  private_zone = false
}

######################################### RESOURCES #################

resource "aws_vpc" "main" {
  cidr_block                       = var.aws_vpc_cidr
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false

  tags = {
    Name    = "${var.project}-vpc"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_subnet" "public" {
  count             = var.availability_zones
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.aws_vpc_cidr, 8, count.index + 11)

  tags = {
    Name      = "${var.project}-public-${count.index}"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }

}


resource "aws_subnet" "private" {
  count                   = var.availability_zones
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.aws_vpc_cidr, 8, count.index + 1)
  map_public_ip_on_launch = false


  tags = {
    Name      = "${var.project}-private-${count.index}"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}

resource "aws_eip" "nat" {
  count = var.availability_zones
  vpc   = true

  tags = {
    Name    = "${var.project}-eip-natgw-${count.index}"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_nat_gateway" "natgw" {
  count         = var.availability_zones
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)

  tags = {
    Name    = "${var.project}-natgw-${count.index}"
    Project = var.project
    Owner   = var.owner
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
    Owner   = var.owner
  }
}

resource "aws_route_table" "rt-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "${var.project}-rt-public"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }
}

resource "aws_route_table" "rt-private" {
  count  = var.availability_zones
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[count.index].id
  }
  tags = {
    Name      = "${var.project}-rt-private"
    Attribute = "private"
    Project   = var.project
    Owner     = var.owner
  }
}




