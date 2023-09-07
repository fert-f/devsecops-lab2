# module "vpc_cni_irsa_role" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name = "${var.stack_name}-vpc-cni"

#   attach_vpc_cni_policy = true
#   vpc_cni_enable_ipv4   = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:vpc-cni"]
#     }
#   }
# }

module "cert_manager_irsa_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  count                         = var.domain_name != "test.local" ? 1 : 0
  role_name                     = "${var.stack_name}-cert_manager_irsa"
  role_description              = "IRSA for cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected[0].zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }
}

module "external_dns_irsa_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  count                         = var.domain_name != "test.local" ? 1 : 0
  role_name                     = "${var.stack_name}-external_dns_irsa"
  role_description              = "IRSA for cert-manager"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected[0].zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

module "lb_controller_irsa_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  count                                  = var.domain_name != null ? 1 : 0
  role_name                              = "${var.stack_name}-lb_controller_irsa_role"
  role_description                       = "IRSA for AWS load balancer controller"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:lb-controller"]
    }
  }
}

module "ebs_controller_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name             = "${var.stack_name}-ebs_controller_irsa_role"
  role_description      = "IRSA for AWS EBS controller"
  attach_ebs_csi_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "karpenter_irsa_role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name             = "${var.stack_name}-karpenter_irsa_role"
  role_description      = "IRSA for Karpenter"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name       = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = ["arn:aws:iam::486271973780:role/spot-node-group-2023090704191122850000000b"]
  # karpenter_controller_node_iam_role_arns = [module.eks.module.self_managed_node_group["spot"].iam_role_arn]
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}
