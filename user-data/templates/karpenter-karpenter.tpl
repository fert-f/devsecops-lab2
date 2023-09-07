---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: karpenter
  namespace: karpenter
spec:
  interval: 60m
  url: oci://public.ecr.aws/karpenter/karpenter
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: karpenter
  namespace: karpenter
spec:
  suspend: false
  interval: 5m
  install:
    remediation:
      retries: -1
    timeout: 20m
  chart:
    spec:
      chart: karpenter
      version: ${version_helm_karpenter}
      sourceRef:
        kind: HelmRepository
        name: karpenter
        namespace: karpenter
      interval: 10m
  values:
    settings:
      aws:
        clusterName: '${stack_name}'
        interruptionQueueName: '${stack_name}'
        defaultInstanceProfile: ${stack_name}-KarpenterNodeInstanceProfile
        # enablePodENI: false
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: '${karpenter_irsa_role}'
    controller:
      resources:
        request:
          cpu: "50m"
          mem: "64Mi"
        limit:
          cpu: "1"
          mem: "512Mi"
    # tags: []

    # region: '${region}'
    # vpcId: '${vpcId}'
    # ingressClassConfig:
    #   default: true
      # Enable cert-manager
    # enableCertManager: true
    # cluster:
    # # Cluster DNS domain (required for requesting TLS certificates)
    #   dnsDomain: '${domain_name}'
    # defaultTags: {}
    # default_tag1: value1
    # default_tag2: value2
    # replicaCount: 1
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller