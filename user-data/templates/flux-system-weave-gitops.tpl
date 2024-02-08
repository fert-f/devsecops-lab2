---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: weaveworks-gitops
  namespace: flux-system
spec:
  interval: 60m
  type: oci
  url: oci://ghcr.io/weaveworks/charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  annotations:
    metadata.weave.works/description: This is the Weave GitOps Dashboard.  It provides a simple way to get insights into your GitOps workloads.
    kubernetes.io/documentation: https://docs.gitops.weave.works/docs/references/helm-reference/
  name: weaveworks-gitops
  namespace: flux-system
spec:
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  install:
    timeout: 20m
    remediation:
      retries: -1
  chart:
    spec:
      chart: weave-gitops
      version: ${version_helm_ww-gitops}
      sourceRef:
        kind: HelmRepository
        name: weaveworks-gitops
        namespace: flux-system
  interval: 60m
  values:
    adminUser:
      create: true
      passwordHash: $2y$10$zTRdq9bLcEmGF27exGcKZ.LnSNIOpwV.n5H7tLP4/oyuSRGjTk7Ai
      username: admin
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller
    resources:
      requests:
        cpu: "10m"
        memory: "32Mi"
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: alb
        external-dns.alpha.kubernetes.io/ttl: '120'
        alb.ingress.kubernetes.io/scheme: internet-facing
        # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
        alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
        alb.ingress.kubernetes.io/group.name: mgmt
        alb.ingress.kubernetes.io/backend-protocol: HTTP
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/tags: "loki=true"
        alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
        alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
        alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
      hosts:
        - host: flux.${stack_name}.${domain_name}
          paths:
            - path: /
              pathType: ImplementationSpecific
