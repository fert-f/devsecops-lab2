data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "ubuntu-server-2204" {
  most_recent = true

  filter {
    name = "name"
    # values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  owners = ["amazon"]
}

data "aws_ami" "amazon-eks-linux-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.eks_cluster_version}-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}

data "aws_route53_zone" "selected" {
  count        = var.domain_name != "test.local" ? 1 : 0
  name         = "${var.domain_name}."
  private_zone = false
}