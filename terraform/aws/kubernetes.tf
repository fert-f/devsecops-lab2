
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

locals {
  kubectl_apply = [
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.66.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml",
    "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.66.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml"
  ]
}

data "http" "manifests" {
  count     = length(local.kubectl_apply)
  url = element(local.kubectl_apply, count.index)
  request_headers = {
    Accept = "application/json"
  }
}
resource "kubectl_manifest" "manifests" {
  count     = length(data.http.manifests)
  yaml_body = data.http.manifests[count.index].body
  apply_only = true
}

resource "kubectl_manifest" "flux-ns" {
    yaml_body = <<YAML
---
apiVersion: v1
kind: Namespace
metadata:
  name: flux-system
YAML
    apply_only = true
}

data "kubectl_file_documents" "flux" {
    content = file("../../user-data/flux/flux-system/gotk-components.yaml")
}
resource "kubectl_manifest" "flux" {
    count     = length(data.kubectl_file_documents.flux.documents)
    yaml_body = element(data.kubectl_file_documents.flux.documents, count.index)
    depends_on = [ kubectl_manifest.flux-ns ]
    apply_only = true
}

data "kubectl_path_documents" "flux-sync" {
    pattern = "../../user-data/flux/flux-system/git-repo.tpl"
    vars = {
        branch = var.gitops_branch
    }
}
resource "kubectl_manifest" "flux-sync" {
    count     = length(data.kubectl_path_documents.flux-sync.documents)
    yaml_body = element(data.kubectl_path_documents.flux-sync.documents, count.index)
    depends_on = [ kubectl_manifest.flux ]
    apply_only = true
}

data "kubectl_file_documents" "flux-gotk-sync" {
    content = file("../../user-data/flux/flux-system/gotk-sync.yaml")
}
resource "kubectl_manifest" "flux-gotk-sync" {
    count     = length(data.kubectl_file_documents.flux-gotk-sync.documents)
    yaml_body = element(data.kubectl_file_documents.flux-gotk-sync.documents, count.index)
    depends_on = [ kubectl_manifest.flux ]
    apply_only = true
}


