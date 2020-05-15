variable "aws_region" {
  type        = string
  description = "AWS Region this resource will be deployed"
  default     = "us-east-2"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile to be used"
  default     = "default"
}

variable "server_port" {
  type        = number
  default     = 80
  description = "Port the ec2 will listen on"
}
