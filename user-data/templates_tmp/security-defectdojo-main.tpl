---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: defectdojo
  namespace: security
spec:
  interval: 10m0s
  ref:
    branch: ${version_git_defectdojo}
  url: https://github.com/DefectDojo/django-DefectDojo
  ignore: |
    # exclude all
    /*
    # include charts directory
    !helm/defectdojo
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: defectdojo
  namespace: security
spec:
  chart:
    spec:
      chart: ./helm/defectdojo
      version: ${version_helm_defectdojo}
      sourceRef:
        kind: GitRepository
        name: defectdojo
        namespace: security
  interval: 60m
  install:
    remediation:
      retries: -1
    timeout: 20m
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  values:
    createSecret: false
    createRabbitMqSecret: false
    createPostgresqlSecret: false
    tag: ${version_app_defectdojo}
    host: defectdojo.${stack_name}.${domain_name}
    rabbitmq:
      resources:
        requests:
          memory: 32Mi
          cpu: 50m
      image:
        repository: bitnami/rabbitmq
        tag: 3.11-debian-11
      auth:
        existingPasswordSecret: defectdojo-rabbitmq-specific
        existingErlangSecret: defectdojo-rabbitmq-specific
      persistence:
        # storageClass: local-path
        size: 1Gi
    postgresql:
      enabled: true
      primary:
        resources:
          requests:
            cpu: "50m"
            memory: "32Mi"
    django:
      uwsgi:
        resources:
          requests:
            memory: 32Mi
            cpu: 50m
      nginx:
        resources:
          requests:
            memory: 32Mi
            cpu: 50m
      ingress:
        activateTLS: false
        annotations:
          #ingress.kubernetes.io/proxy-body-size: 8m
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
    imagePullPolicy: IfNotPresent
    monitoring:
      enabled: false
      prometheus:
        enabled: false
    database: postgresql
    celery:
      beat:
        resources:
          requests:
            memory: 32Mi
            cpu: 50m
      worker:
        resources:
          requests:
            memory: 32Mi
            cpu: 50m
---
apiVersion: v1
data:
  DD_ADMIN_PASSWORD: YWRtaW4=
  DD_CREDENTIAL_AES_256_KEY: dWlweGNVQ3NmT0VBU0lFem9LS3VEbURWUGNGdU9jWmd4UEhyV2ttWnNlRXVLb1ZFeERlSkhDYVplWXl6VU9wRGZDd1Jmam93cElZck1uUUtkRVZFUVZacml5S2JwV1Vadk11RU9Gc3B2d2xwZU91cFdmUGJrY0p5d21PbkVEWEY=
  DD_SECRET_KEY: WGdycUpGbFFCeHpwQVltVWtUamRjT1dyWGhEcndNTENYcklnWnhwRUJDalBkcWR3ZFNJWG5Od25EemFGQ3dxZFBHWm1TVWdTYndRb09tT0dGWG1aV3JJVVptTnNEZ0puQ1psYm9NdkVPT1dCcWdkbm1Zb2pXVG1wTmFqZmtvUHA=
  METRICS_HTTP_AUTH_PASSWORD: bWhEakRxcEVsQ1dUQ21LYmN2bkJad1VDdnNWVHlGT3Q=
kind: Secret
metadata:
  name: defectdojo
  namespace: security
---
apiVersion: v1
data:
  rabbitmq-erlang-cookie: a3YzNTg4ZG9ta3VzZWg3aWJzdW93aHZoNTFmc3NhYnA=
  rabbitmq-password: aHFzMjY1dzR1dHoz
kind: Secret
metadata:
  name: defectdojo-rabbitmq-specific
  namespace: security
---
apiVersion: v1
data:
  postgresql-password: VnBiQmZMVlZ3alNkeUZBZg==
  postgresql-postgres-password: TFhhQmh6Qkt5R2N0aEZMUA==
kind: Secret
metadata:
  creationTimestamp: null
  name: defectdojo-postgresql-specific
  namespace: security
