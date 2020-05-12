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
