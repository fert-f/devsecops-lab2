---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: eks
  namespace: kube-system
spec:
  interval: 60m
  url: https://aws.github.io/eks-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
spec:
  suspend: false
  interval: 5m
  # releaseName: aws-load-balancer-controller
  install:
    remediation:
      retries: -1
    timeout: 20m
  chart:
    spec:
      chart: aws-load-balancer-controller
      version: ${version_helm_alb}
      sourceRef:
        kind: HelmRepository
        name: eks
        namespace: kube-system
      interval: 10m
  values:
    clusterName: '${stack_name}'
    serviceAccount:
      name: lb-controller
      annotations:
        eks.amazonaws.com/role-arn: '${lb_controller_irsa_role}'
    region: '${region}'
    vpcId: '${vpcId}'
    ingressClassConfig:
      default: true
      # Enable cert-manager
    # enableCertManager: true
    # cluster:
    # # Cluster DNS domain (required for requesting TLS certificates)
    #   dnsDomain: '${domain_name}'
    defaultTags: {}
    # default_tag1: value1
    # default_tag2: value2
    replicaCount: 1
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller