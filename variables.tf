variable "aws_region" {
  description = "AWS Region e.g us-east-1"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS cli profile (e.g. `default`)"
  type        = string
  default     = "default"
}

variable "hosted_zone" {
  type        = string
  description = "Route53 Hosted Zone for creating records (without . suffix, e.g. `sachinmaharana.dev`)"
  default     = "sachinm.site"
}


variable "aws_vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.23.0.0/16"
}

variable "owner" {
  description = "Owner name used for tags"
  type        = string
  default     = "sachinm.site"
}

variable "project" {
  description = "Project name used for tags"
  type        = string
  default     = "emma-aws"
}

variable "availability_zones" {
  description = "Number of different AZs to use"
  type        = number
  default     = 3
}
