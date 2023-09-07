---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-deployer
  namespace: jenkins
subjects:
  - kind: ServiceAccount
    name: jenkins
    namespace: jenkins
roleRef:
  kind: ClusterRole
  name: jenkins-deployer
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-deployer
  namespace: jenkins
rules:
  - apiGroups: ["*"]
    resources:
      - configmaps
      - deployments
      - pods
      - pods/log
      - services
      - cronjobs
      - jobs
      - secrets
      - helmreleases
      - ingresses
      - persistentvolumeclaims
      - persistentvolumes
      - horizontalpodautoscalers
      - namespaces
      - statefulsets
      - daemonsets
      - rolebindings
      - roles
      - serviceaccounts
      - limitranges
      - replicasets
    verbs: ["*"]
---