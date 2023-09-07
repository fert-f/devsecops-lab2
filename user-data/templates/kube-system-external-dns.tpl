---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: external-dns
  namespace: kube-system
spec:
  interval: 60m
  url: https://kubernetes-sigs.github.io/external-dns/
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: external-dns
  namespace: kube-system
spec:
  suspend: false
  interval: 5m
  install:
    remediation:
      retries: -1
    timeout: 20m
  chart:
    spec:
      chart: external-dns
      version: 1.13.0
      sourceRef:
        kind: HelmRepository
        name: external-dns
        namespace: kube-system
      interval: 10m
  values:
    extraArgs:
    - --domain-filter=${domain_name}
    - --aws-zone-type=public
    AWSAccountId: '${aws_account}'
    TXTOwnerID: '${stack_name}'
    #IAMRoleArn: $${external-dns-arn}
    policy: sync
    serviceAccount:
      name: external-dns
      annotations:
        eks.amazonaws.com/role-arn: '${external_dns_irsa_role}'
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller