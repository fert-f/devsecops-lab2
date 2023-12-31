---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-dependency-check
  namespace: jenkins
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  #storageClassName: local-path
  #volumeMode: Filesystem
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-maven
  namespace: jenkins
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  #storageClassName: local-path
  #volumeMode: Filesystem
