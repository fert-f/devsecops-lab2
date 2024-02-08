apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: aquasecurity
  namespace: security
spec:
  interval: 60m
  url: https://aquasecurity.github.io/helm-charts/
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: trivy
  namespace: security
spec:
  install:
    timeout: 20m
    remediation:
      retries: -1
  suspend: false
  interval: 30m
  chart:
    spec:
      chart: trivy
      version: ${version_helm_trivy}
      sourceRef:
        kind: HelmRepository
        name: aquasecurity
        namespace: security
      interval: 10m
  values:
    tolerations:
      - key: role
        operator: "Equal"
        value: worker
    nodeSelector:
      node.kubernetes.io/role: worker
    service:
      port: 9090
    trivy:
      vulnType: "os,library"
    persistence:
      enabled: true
    resources:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 10m
        memory: 64Mi
