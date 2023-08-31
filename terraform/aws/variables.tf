locals {
  # name   = "ex-${basename(path.cwd)}"
  name   = "ex-${replace(basename(path.cwd), "_", "-")}"
  region = var.aws_region

  vpc_cidr = var.cidr_block
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags     = {}
}

variable "whitelisted_cidrs" {
  description = "Whitelisted public CIDRs"
  default     = ["94.158.63.210/31", "84.54.75.194/31"]
}

variable "stack_name" {
  description = "Stack name to tag your resources"
  type        = string
  default     = "devsecops"
}
variable "eks_cluster_version" {
  description = "Version of EKS cluster"
  type        = string
  default     = "1.24"
}

variable "worker_instanse_size" {
  description = "Worker node type"
  type        = string
  # default = "t3.large"  # 0.096 USD per Hour, burstable
  default = "r6a.large" # 0.1368 USD per Hour, AMD based
  # default = "r5a.large" # 0.137 USD per Hour, AMD based
  # default = "t3a.medium" # 0.0432 USD per Hour, AMD based
}

variable "ssh_key_path" {
  description = "Path for new ssh key for all EC2 instances"
  type        = string
  default     = "~/.ssh/devsecops_aws_terraform.pem"
}

variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = "eu-central-1"
}

variable "gitops_branch" {
  description = "GitOps branch to use"
  type        = string
  default     = "main"
}

variable "cidr_block" {
  description = "CIDR for main VPC"
  type        = string
  default     = "10.0.16.0/20"
}
