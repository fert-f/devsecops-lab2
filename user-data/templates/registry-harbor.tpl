apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: harbor
  namespace: registry
spec:
  interval: 60m
  url: https://helm.goharbor.io
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: harbor
  namespace: registry
spec:
  suspend: false
  interval: 5m
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  chart:
    spec:
      chart: harbor
      version: ${version_helm_harbor}
      sourceRef:
        kind: HelmRepository
        name: harbor
        namespace: registry
      interval: 10m
  install:
    timeout: 20m
    remediation:
      retries: -1
  values:
    logLevel: debug
    expose:
      type: ingress
      ingress:
        annotations:
          kubernetes.io/ingress.class: alb
          external-dns.alpha.kubernetes.io/ttl: '120'
          alb.ingress.kubernetes.io/scheme: internet-facing
          # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
          alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
          alb.ingress.kubernetes.io/group.name: mgmt
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/tags: "harbor=true"
          alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
          alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
        hosts: 
          core: core.${stack_name}.${domain_name}
          notary: notary.${stack_name}.${domain_name}
    persistence:
      persistentVolumeClaim:
        registry:
          # storageClass: local-path
          size: 5Gi
        chartmuseum:
          # storageClass: local-path
          size: 1Gi
        database:
          # storageClass: local-path
          size: 5Gi
        redis:
          # storageClass: local-path
          size: 1Gi
        trivy:
          # storageClass: local-path
          size: 1Gi
        jobservice:
          jobLog:
            # storageClass: local-path
            size: 1Gi
          scanDataExports:
            # storageClass: local-path
    externalURL: https://core.${domain_name}:443
    notary:
      enabled: false
    database:
      internal:
        resources:
          requests:
            cpu: "30m"
            memory: "64Mi"
          limits:
            cpu: "500m"
            memory: "1024Mi"
    trivy:
      resources:
        requests:
          cpu: "10m"
          memory: "32Mi"
    # harborAdminPassword: Harbor12345
    # chartmuseum:
    #   enabled: false

    # metrics:
    #   enabled: true
    #   serviceMonitor:
    #     enabled: true
    # trace.enabled: 