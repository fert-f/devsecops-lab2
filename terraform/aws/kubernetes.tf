
# resource "helm_release" "cilium" {
#   namespace        = "kube-system"
#   create_namespace = true

#   name                = "cilium"
#   repository          = "https://helm.cilium.io/"
#   chart               = "cilium"
#   version             = "1.12.10"

#   values = [
#     "${file("../../user-data/values-cilium.yaml")}"
#   ]
# }

# data "http" "external_manifests" {
#   count = length(local.kubectl_apply)
#   url   = element(local.kubectl_apply, count.index)
#   request_headers = {
#     Accept = "application/json"
#   }
# }

# resource "kubectl_manifest" "external_manifests" {
#   count      = length(data.http.external_manifests)
#   yaml_body  = data.http.external_manifests[count.index].body
#   apply_only = true
# }

# resource "helm_release" "this" {
#   repository       = "https://fluxcd-community.github.io/helm-charts"
#   depends_on       = [module.eks]
#   chart            = "flux2"
#   name             = "flux2"
#   namespace        = "flux-system"
#   create_namespace = true
#   wait             = false
#   timeout          = 600
# }



module "templates" {
  source   = "./modules/template"
  for_each = fileset("../../user-data/templates", "*")
  file     = each.key
  vars = {
    acm_certificate_arn            = module.acm.acm_certificate_arn
    aws_account                    = data.aws_caller_identity.current.account_id
    cert_manager_irsa_role         = var.domain_name != "test.local" ? module.cert_manager_irsa_role[0].iam_role_arn : "null"
    domain_name                    = var.domain_name
    ebs_controller_irsa_role       = module.ebs_controller_irsa_role.iam_role_arn
    external_dns_irsa_role         = var.domain_name != "test.local" ? module.external_dns_irsa_role[0].iam_role_arn : "null"
    karpenter_instance_profile_name = module.karpenter.instance_profile_name
    karpenter_irsa_role_arn        = module.karpenter.irsa_arn
    karpenter_queue_name           = module.karpenter.queue_name
    cluster_endpoint               = module.eks.cluster_endpoint
    lb_controller_irsa_role        = var.domain_name != "test.local" ? module.lb_controller_irsa_role[0].iam_role_arn : "null"
    region                         = var.aws_region
    route53_zone_id                = var.domain_name != "test.local" ? data.aws_route53_zone.selected[0].zone_id : "null"
    sg_whitelisted                 = aws_security_group.whitelisted.id
    stack_name                     = var.stack_name
    version_app_defectdojo         = var.versions["app_defectdojo"]
    version_app_metrics            = var.versions["app_metrics"]
    version_git_defectdojo         = var.versions["git_defectdojo"]
    version_helm_alb               = var.versions["helm_alb"]
    version_helm_cert-manager      = var.versions["helm_cert-manager"]
    version_helm_defectdojo        = var.versions["helm_defectdojo"]
    version_helm_ebs               = var.versions["helm_ebs"]
    version_helm_external-dns      = var.versions["helm_external-dns"]
    version_helm_harbor            = var.versions["helm_harbor"]
    version_helm_karpenter         = var.versions["helm_karpenter"]
    version_helm_promstack         = var.versions["helm_promstack"]
    version_helm_promtail          = var.versions["helm_promtail"]
    version_helm_sonarqube         = var.versions["helm_sonarqube"]
    version_helm_trivy             = var.versions["helm_trivy"]
    version_helm_ww-gitops         = var.versions["helm_ww-gitops"]
    vpcId                          = module.vpc.vpc_id
  }
}