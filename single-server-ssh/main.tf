data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}


locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}


resource "aws_security_group" "instance" {
  name = "instance-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.workstation-external-cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_key_pair" "ssh" {
  count      = var.aws_key_pair_name == null ? 1 : 0
  key_name   = "${var.owner}-${var.project}"
  public_key = file(var.ssh_public_key_path)
}


resource "aws_instance" "instance" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  key_name               = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  user_data              = templatefile("${path.module}/userdata-server.sh", {})
  tags = {
    Name = "instance-ec2"
  }
}


output "public_ip" {
  value       = aws_instance.instance.public_ip
  description = "Public IP"
}



