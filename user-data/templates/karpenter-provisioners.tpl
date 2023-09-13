apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  #taints:
  #  - key: example.com/special-taint
  #    effect: NoSchedule
  labels:
    "node.kubernetes.io/role": worker
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: karpenter.k8s.aws/instance-category
      operator: In
      values: [c, m, r]
    - key: "karpenter.k8s.aws/instance-cpu"
      operator: In
      values: ["1", "2", "4"]
    - key: "karpenter.k8s.aws/instance-hypervisor"
      operator: In
      values: ["nitro"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
  limits:
    resources:
      cpu: "4"
      memory: 16Gi
  providerRef:
    name: default
  consolidation: 
    enabled: true
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  amiFamily: AL2
  tags:
    Name: "${stack_name}-karpenter-default"
  subnetSelector:
    kubernetes.io/cluster/${stack_name}: owned
  securityGroupSelector:
    kubernetes.io/cluster/${stack_name}: owned