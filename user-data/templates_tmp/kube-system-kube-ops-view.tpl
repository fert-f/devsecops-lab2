---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: kube-ops-view
  namespace: kube-system
spec:
  interval: 60m
  url: https://charts.bitnami.com/bitnami
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: kube-ops-view
  namespace: kube-system
spec:
  suspend: false
  interval: 5m
  install:
    remediation:
      retries: -1
  chart:
    spec:
      chart: kubeapps
      version: ${version_helm_kube-ops-view}
      sourceRef:
        kind: HelmRepository
        name: kube-ops-view
        namespace: kube-system
      interval: 10m
  values:
    ingress:
      annotations:
        kubernetes.io/ingress.class: alb
        external-dns.alpha.kubernetes.io/ttl: '120'
        alb.ingress.kubernetes.io/scheme: internet-facing
        alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
        alb.ingress.kubernetes.io/group.name: mgmt
        alb.ingress.kubernetes.io/backend-protocol: HTTP
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/tags: "kube-ops-view=true"
        alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
        alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
      hostname: kube-ops-view.${stack_name}.${domain_name}
    packaging:
      helm:
        enabled: false
      flux:
        enabled: true
---