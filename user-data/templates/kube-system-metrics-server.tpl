---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: kubernetes-sigs
  namespace: kube-system
spec:
  interval: 60m
  url: https://kubernetes-sigs.github.io/metrics-server/
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  suspend: false
  interval: 5m
  install:
    remediation:
      retries: -1
  chart:
    spec:
      chart: metrics-server
      version: ${version_helm_metrics}
      sourceRef:
        kind: HelmRepository
        name: kubernetes-sigs
        namespace: kube-system
      interval: 10m
  values:
    args:
    - --kubelet-insecure-tls
    tolerations:
      - key: role
        operator: "Equal"
        value: controller
    nodeSelector:
      node.kubernetes.io/role: controller
---