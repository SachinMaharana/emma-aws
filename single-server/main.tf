resource "aws_instance" "ss" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ss.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hey Sachin" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF

  tags = {
    Name = "single-server"
  }
}

resource "aws_security_group" "ss" {
  name = "single-server"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "public_ip" {
  value       = aws_instance.ss.public_ip
  description = "Public IP"
}
