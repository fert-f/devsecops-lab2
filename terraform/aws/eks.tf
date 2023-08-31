module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "~> 19.0"
  cluster_name                         = var.stack_name
  cluster_version                      = var.eks_cluster_version
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = concat(var.whitelisted_cidrs, ["${chomp(data.http.myip.body)}/32"])
  cluster_addons = {
    # coredns = {
    #   most_recent = true
    # }
    # kube-proxy = {
    #   most_recent = true
    # }
    # vpc-cni = {
    #   most_recent = true
    # }

  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  self_managed_node_group_defaults = {
    vpc_security_group_ids = [aws_security_group.this.id]
    iam_role_additional_policies = {
      ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "optional"
      http_put_response_hop_limit = 5
    }

    # instance_refresh = {
    #   strategy = "Rolling"
    #   preferences = {
    #     min_healthy_percentage = 66
    #   }
    # }
    # enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.stack_name}" : "owned",
    }
  }

  self_managed_node_groups = {
    spot = {
      ami_id       = data.aws_ami.amazon-eks-linux-2.id
      min_size     = 1
      desired_size = 1
      max_size     = 2
      key_name     = module.pki.aws_key_name

      instance_type = var.worker_instanse_size
      instance_market_options = {
        market_type = "spot"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 25
            volume_type = "gp3"
            encrypted = false
            delete_on_termination = true
            # iops                  = 3000
            # throughput            = 150
            # kms_key_id            = module.ebs_kms_key.key_arn
          }
        }
      }
      enable_bootstrap_user_data = true
      pre_bootstrap_user_data    = <<-EOT
        echo "foo"
        export FOO=bar
      EOT
      bootstrap_extra_args       = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      post_bootstrap_user_data = <<-EOT
        cd /tmp
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
      EOT
    }
  }

  # aws-auth configmap
  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = data.aws_caller_identity.current.arn
      username = "masterRole"
      groups   = ["system:masters"]
    },
  ]

  # aws_auth_users = [
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user1"
  #     username = "user1"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:aws:iam::66666666666:user/user2"
  #     username = "user2"
  #     groups   = ["system:masters"]
  #   },
  # ]

  # aws_auth_accounts = [
  #   "777777777777",
  #   "888888888888",
  # ]

  tags = local.tags
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Security group
resource "aws_security_group" "this" {
  name   = "${var.stack_name}-this"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Inter SG communication"
    self        = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Rule for Stack IPs"
    cidr_blocks = [var.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Rule for terraform owner"
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Whitelisted public CIDRs"
    cidr_blocks = var.whitelisted_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Rule for egress traffic"
    cidr_blocks = ["0.0.0.0/0"]
  }
}