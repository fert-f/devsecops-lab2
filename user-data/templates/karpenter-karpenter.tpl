---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: karpenter
  namespace: karpenter
spec:
  type: "oci"
  interval: 5m0s
  url: oci://public.ecr.aws/karpenter
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
      version: "v${version_helm_karpenter}"
      sourceRef:
        kind: HelmRepository
        name: karpenter
        namespace: karpenter
      interval: 10m
  values:
    replicas: 1
    settings:
      aws:
        clusterName: '${stack_name}'
        clusterEndpoint: '${cluster_endpoint}'
        interruptionQueueName: '${karpenter_queue_name}'
        defaultInstanceProfile: '${karpenter_instance_profile_name}'
        enablePodENI: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: '${karpenter_irsa_role_arn}'
    controller:
      env:
        - name: AWS_ENI_LIMITED_POD_DENSITY
          value: 'false'
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