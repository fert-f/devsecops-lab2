---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: flux-system
  namespace: flux-system
spec:
  ignore: |-
    /*
    !/user-data/flux
  interval: 1m0s
  ref:
    branch: ${branch}
  url: https://github.com/fert-f/devsecops-lab2