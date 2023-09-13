locals {
  # name   = "ex-${basename(path.cwd)}"
  name   = "ex-${replace(basename(path.cwd), "_", "-")}"
  region = var.aws_region

  vpc_cidr = var.cidr_block
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
  tags     = {}
  external_manifests = [
    "https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-${var.versions["helm_promstack"]}/charts/kube-prometheus-stack/charts/crds/crds/crd-servicemonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-community/helm-charts/kube-prometheus-stack-${var.versions["helm_promstack"]}/charts/kube-prometheus-stack/charts/crds/crds/crd-prometheusrules.yaml",
    # "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.66.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml",
    # "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.66.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml",
    "https://github.com/cert-manager/cert-manager/releases/download/v${var.versions["helm_cert-manager"]}/cert-manager.crds.yaml",
    "https://raw.githubusercontent.com/aws/karpenter/v${var.versions["helm_karpenter"]}/pkg/apis/crds/karpenter.sh_provisioners.yaml",
    "https://raw.githubusercontent.com/aws/karpenter/v${var.versions["helm_karpenter"]}/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml"
  ]
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
  default     = "1.25"
}

# variable "worker_instanse_size" {
#   description = "Worker node type"
#   type        = string
#   # default = "t3.large"  # 0.096 USD per Hour, burstable
#   default = "r6a.large" # 0.1368 USD per Hour, AMD based
#   # default = "r5a.large" # 0.137 USD per Hour, AMD based
#   # default = "t3a.medium" # 0.0432 USD per Hour, AMD based
#   # default = ["r6a.large", "r6.large", "r5.large", "r5a.large"] # 0.1368 USD per Hour, AMD based
# }

variable "worker_group_resources" {
  description = "Worker instance resource requirements for ASG"
  type        = map(string)
  # default     = "4096"
  # default     = "16384"
  default = {
    cpu_min = "2"
    cpu_max = "4"
    mem_min = "4000"
    mem_max = "5000"
  }
}
# variable "worker_group_cpu" {
#   description = "Worker node vCPU count"
#   type        = string
#   default     = "2"
# }

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
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Domain name that will be used for ingress"
  type        = string
  default     = "test.local"
}

variable "versions" {
  default = {
    app_defectdojo     = "2.23.0"
    app_metrics        = "3.8.2"
    git_defectdojo     = "release/2.23.2"
    helm_alb           = "1.6.0"
    helm_cert-manager  = "1.12.3"
    helm_defectdojo    = "1.6.72"
    helm_ebs           = "2.22.0"
    helm_external-dns  = "1.13.0"
    helm_harbor        = "1.12.2"
    helm_sonarqube     = "10.1.0+628"
    helm_promtail      = "6.11.5"
    helm_promstack     = "49.2.0"
    helm_trivy         = "0.7.0"
    helm_ww-gitops     = "4.0.16"
    helm_karpenter     = "0.30.0"
    helm_metrics       = "3.8.2"
    helm_kube-ops-view = "13.1.1"
  }
}