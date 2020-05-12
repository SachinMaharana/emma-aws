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

variable "ssh_public_key_path" {
  description = "SSH public key path (to create a new AWS Key Pair from existing local SSH public RSA key)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "aws_key_pair_name" {
  description = "AWS Key Pair name to use for EC2 Instances (if already existent)"
  type        = string
  default     = null
}

variable "pod_cidr" {
  description = "The first two octets for the Pod network CIDR (used in Worker UserData to generate POD_CIDR envvar)"
  type        = string
  default     = "10.200"
}
variable "bastion_max_size" {
  description = "Maximum number of EC2 instances for Bastion AutoScalingGroup"
  type        = number
  default     = 1
}


variable "bastion_min_size" {
  description = "Minimum number of EC2 instances for Bastion AutoScalingGroup"
  type        = number
  default     = 1
}

variable "bastion_size" {
  description = "Desired number of EC2 instances for Bastion AutoScalingGroup"
  type        = number
  default     = 1
}

variable "etcd_max_size" {
  description = "Maximum number of EC2 instances for etcd AutoScalingGroup"
  type        = number
  default     = 3
}

variable "etcd_min_size" {
  description = "Minimum number of EC2 instances for etcd AutoScalingGroup"
  type        = number
  default     = 3
}

variable "etcd_size" {
  description = "Desired number of EC2 instances for etcd AutoScalingGroup"
  type        = number
  default     = 3
}

variable "master_max_size" {
  description = "Maximum number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 3
}

variable "master_min_size" {
  description = "Minimum number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 3
}



variable "master_size" {
  description = "Desired number of EC2 instances for K8s Master AutoScalingGroup"
  type        = number
  default     = 3
}

variable "worker_max_size" {
  description = "Maximum number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 3
}

variable "worker_min_size" {
  description = "Minimum number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 3
}

variable "worker_size" {
  description = "Desired number of EC2 instances for K8s Worker AutoScalingGroup"
  type        = number
  default     = 3
}

variable "bastion_instance_type" {
  description = "EC2 instance type for Bastion Host"
  type        = string
  default     = "t3a.small"
}

variable "etcd_instance_type" {
  description = "EC2 instance type for etcd instances"
  type        = string
  default     = "t3a.small"
}

variable "master_instance_type" {
  description = "EC2 instance type for K8s master instances"
  type        = string
  default     = "t3a.small"
}

variable "worker_instance_type" {
  description = "EC2 instance type for K8s worker instances"
  type        = string
  default     = "t3a.small"
}
