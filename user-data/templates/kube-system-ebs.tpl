---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: ebs-controller
  namespace: kube-system
spec:
  interval: 60m
  url: https://kubernetes-sigs.github.io/aws-ebs-csi-driver
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: aws-ebs-csi-driver
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
      chart: aws-ebs-csi-driver
      version: ${version_helm_ebs}
      sourceRef:
        kind: HelmRepository
        name: ebs-controller
        namespace: kube-system
      interval: 10m
  values:
    clusterName: '${stack_name}'
    controller:
      additionalArgs:
        - --k8s-tag-cluster-id
        - '${stack_name}'
      replicaCount: 1
      serviceAccount:
        name: ebs-csi-controller-sa
        annotations:
          eks.amazonaws.com/role-arn: '${ebs_controller_irsa_role}'
      region: '${region}'
      extraVolumeTags:
        "kubernetes/cluster/${stack_name}": owned
      tolerations:
        - key: role
          operator: "Equal"
          value: controller
      nodeSelector:
        node.kubernetes.io/role: controller
    node:
      tolerations:
        - key: role
          operator: "Equal"
          value: controller
      # nodeSelector:
      #   node.kubernetes.io/role: controller
    storageClasses:
    - name: ebs-gp3
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
      labels:
        type: ebs
      reclaimPolicy: Delete
      parameters:
        encrypted: "false"
        type: gp3
        # tagSpecification_1: "pvcnamespace={{ .PVCNamespace }}"
        # tagSpecification_2: "pvcname={{ .PVCName }}"
        # tagSpecification_3: "pvname={{ .PVName }}"
      allowVolumeExpansion: true
      volumeBindingMode: WaitForFirstConsumer
    volumeSnapshotClasses: []

