module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  irsa_tag_key                    = "kubernetes.io/cluster/${var.stack_name}"
  irsa_tag_values                 = ["owned"]

}