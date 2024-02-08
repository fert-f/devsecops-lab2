---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: loki
  namespace: monitoring
spec:
  suspend: false
  interval: 5m
  # releaseName: loki
  dependsOn:
  - name: promstack
  install:
    remediation:
      retries: -1
    timeout: 20m
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  chart:
    spec:
      chart: loki
      version: 5.8.4
      sourceRef:
        kind: HelmRepository
        name: grafana
        namespace: monitoring
      interval: 10m
  values:
    resources:
      requests:
        cpu: 20m
        memory: 100Mi
      limits:
        cpu: 500m
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
        cert-manager.io/cluster-issuer: "letsencrypt-staging"
      hosts:
        host: loki.${stack_name}.${domain_name}
    read:
      replicas: 1
    write:
      replicas: 1
    backend:
      replicas: 1
    # serviceAccount:
    #   create: true
    serviceMonitor:
      enabled: true
      additionalLabels:
        release: "promstack"
      interval: ""
      # additionalLabels:
        # release: prometheus # yaml: unmarshal errors: line 11: mapping key "release" already defined at line 9
      annotations: {}
      scrapeTimeout: 30s
    loki:
      commonConfig:
        replication_factor: 1
      storage:
        type: 'filesystem'
    singleBinary:
      replicas: 1
      tolerations:
        - key: role
          operator: "Equal"
          value: worker
      nodeSelector:
        node.kubernetes.io/role: worker
    gateway:
      tolerations:
        - key: role
          operator: "Equal"
          value: worker
      nodeSelector:
        node.kubernetes.io/role: worker
    grafana-agent-operator:
      tolerations:
        - key: role
          operator: "Equal"
          value: worker
      nodeSelector:
        node.kubernetes.io/role: worker
    monitoring:
      serviceMonitor:
        # annotations: {}
        # enabled: true
        # interval: 15s
        labels:
          release: "promstack"
        # namespaceSelector: {}
        # relabelings: []
        # scheme: http
        # scrapeTimeout: null
        # tlsConfig: null
---
