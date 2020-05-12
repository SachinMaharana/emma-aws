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


resource "aws_route_table_association" "public-rtassoc" {
  count          = var.availability_zones
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.rt-public.id
}

resource "aws_route_table_association" "private-rtassoc" {
  count          = var.availability_zones
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.rt-private[count.index].id
}

resource "aws_key_pair" "ssh" {
  count      = var.aws_key_pair_name == null ? 1 : 0
  key_name   = "${var.owner}-${var.project}"
  public_key = file(var.ssh_public_key_path)
}


data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "bastion" {
  statement {
    sid = "bastion"
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:CreateRoute",
      "ec2:CreateTags",
      "ec2:DescribeAutoScalingGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers",
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }

  statement {
    sid = "route53"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"
    ]
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "bastion-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "bastion" {
  name_prefix = "bastion-"
  role        = aws_iam_role.bastion.id
  policy      = data.aws_iam_policy_document.bastion.json
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "bastion-"
  role        = aws_iam_role.bastion.name
}


data "aws_iam_policy_document" "etcd_worker_master" {
  statement {
    sid = "autoscaling"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project}-etcd-worker-master"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"
  role        = aws_iam_role.etcd_worker_master.id
  policy      = data.aws_iam_policy_document.etcd_worker_master.json
}

resource "aws_iam_instance_profile" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"
  role        = aws_iam_role.etcd_worker_master.name
}


resource "aws_security_group" "bastion-lb" {
  name_prefix = "bastion-lb-"
  description = "Bastion-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion-lb"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-public-lb" {
  name_prefix = "master-public-lb-"
  description = "Master-Public-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-public"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-private-lb" {
  name_prefix = "master-private-lb-"
  description = "Master-Private-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-private"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-"
  description = "Bastion"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "etcd" {
  name_prefix = "etcd-"
  description = "etcd"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-etcd"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master" {
  name_prefix = "k8s-master-"
  description = "K8s Master"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-master"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "k8s-worker-"
  description = "K8s Worker"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-worker"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}
