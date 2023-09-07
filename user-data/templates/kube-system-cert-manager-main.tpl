
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  interval: 60m
  url: 'https://charts.jetstack.io'
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: cert-manager
  namespace: kube-system
spec:
  suspend: false
  interval: 5m
  # releaseName: cert-manager
  install:
    remediation:
      retries: -1
    timeout: 20m
  chart:
    spec:
      chart: cert-manager
      version: ${version_helm_cert-manager}
      sourceRef:
        kind: HelmRepository
        name: cert-manager
        namespace: kube-system
      interval: 10m
  values:
    installCRDs: false
    podLabels:
      component: 'cert-manager'
    webhook:
      podLabels:
        component: 'cert-manager'
      tolerations:
      - key: role
        operator: "Equal"
        value: controller
      nodeSelector:
        node.kubernetes.io/role: controller
    cainjector:
      podLabels:
        component: 'cert-manager'
      tolerations:
      - key: role
        operator: "Equal"
        value: controller
      nodeSelector:
        node.kubernetes.io/role: controller
    startupapicheck:
      tolerations:
      - key: role
        operator: "Equal"
        value: controller
      nodeSelector:
        node.kubernetes.io/role: controller
    serviceAccount:
      name: cert-manager
      annotations:
        eks.amazonaws.com/role-arn: '${cert_manager_irsa_role}'
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller