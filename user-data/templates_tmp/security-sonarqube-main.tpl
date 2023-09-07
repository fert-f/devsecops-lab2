---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: sonarqube
  namespace: security
spec:
  interval: 60m
  url: https://SonarSource.github.io/helm-chart-sonarqube
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: sonarqube
  namespace: security
spec:
  suspend: false
  interval: 5m
  install:
    timeout: 20m
    remediation:
      retries: -1
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  chart:
    spec:
      chart: sonarqube
      version: ${version_helm_sonarqube}
      sourceRef:
        kind: HelmRepository
        name: sonarqube
        namespace: security
      interval: 10m
  values:
    # ApplicationNodes:
    #   resources:
    #     requests:
    #       memory: 256Mi
    #       cpu: 100m
    #   # echo -n "your_secret" | openssl dgst -sha256 -hmac "your_key" -binary | base64
    #   jwtSecret: dZ0EB0KxnF++nr5+4vfTCaun/eWbv6gOoXodiAMqcFo=
    ingress:
      enabled: true
      annotations:
        ingress.kubernetes.io/proxy-body-size: 8m
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
        - name: sonar.${stack_name}.${domain_name}
          # Different clouds or configurations might need /* as the default path
          path: /
          # For additional control over serviceName and servicePort
          # serviceName: someService
          # servicePort: somePort
      annotations: 
        nginx.ingress.kubernetes.io/proxy-body-size: "64m"
    prometheusExporter:
      enabled: true
      config:
        rules:
          - pattern: ".*"
    persistence:
      enabled: true
      size: 2G
      # storageClass: local-path
    resources:
      requests:
        memory: 512Mi
        cpu: 100m
    postgresql:
      persistence:
        enabled: true
        size: 2G
        # storageClass: local-path
      resources:
        requests:
          memory: 128Mi
          cpu: 100m
    serviceAccount:
      create: true
    account:
    # The values can be set to define the current and the (new) custom admin passwords at the startup (the username will remain "admin")
      adminPassword: admin1
      currentAdminPassword: admin

---
