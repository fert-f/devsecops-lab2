apiVersion: batch/v1
kind: Job
metadata:
  name: harbor-jenkins-token
  namespace: jenkins
spec:
  template:
    spec:
      tolerations:
        - key: role
          operator: "Equal"
          value: worker
      nodeSelector:
        node.kubernetes.io/role: worker
      serviceAccountName: harbor-token-generator
      restartPolicy: Never
      containers:
      - name: populate
        image: alpine:latest
        imagePullPolicy: IfNotPresent
        command:
          - sh
          - -c
          - |
              set -xeu
              apk add curl jq
              # Waiting for harbor to come up
              while ! (curl --fail-with-body harbor-core.registry.svc.cluster.local/api/v2.0/ping); do echo "harbor-core.registry yet not responsive..."; sleep 5; done

              # Create robo account
              username=jenkins
              # local harbor-core.registry.svc.cluster.local
              token=$(curl -sk -X POST -u "admin:Harbor12345" http://harbor-core.registry.svc.cluster.local/api/v2.0/robots -H 'accept: application/json' -H 'Content-Type: application/json' \
                -d '{ 
                      "secret": "secureSecret8",
                      "disable": false,
                      "name": "'"$${username}"'",
                      "duration": -1,
                      "level": "system",
                      "permissions": [
                        {
                          "access": [
                            {"action": "list","resource": "repository"},
                            {"action": "pull","resource": "repository"},
                            {"action": "push","resource": "repository"}
                          ],
                          "kind": "project",
                          "namespace": "*"
                        }
                      ]
                }' | jq -r '.secret')

              echo "Generated token: $token"
              echo "Username: $username"
              robotname='robot$'"$${username}"
              echo "Robotname: $robotname"
              usernamepassword64=$(echo -n "$${robotname}:$${token}"| base64 -w0)
              echo "Usernamepassword: $(echo -n $usernamepassword64 | base64 -d)"
              dockerconfigjson='{"auths": {"core.${domain_name}": {"auth": "'"$${usernamepassword64}"'"}}}'
              dockerconfigjson64=$(echo -n $${dockerconfigjson}|base64 -w0)
              echo $dockerconfigjson64 | base64 -d | jq '.auths[].auth|@base64d'

              curl -X POST \
                --header "Content-Type: application/json" \
                --header 'Accept: application/json' \
                --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
                --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
                --data @- \
                https://kubernetes.default:443/api/v1/namespaces/jenkins/secrets <<EOF
              {
                  "apiVersion": "v1",
                  "kind": "Secret",
                  "metadata": {
                    "name": "docker-credentials",
                    "namespace": "jenkins"
                  },
                  "type": "kubernetes.io/dockerconfigjson",
                  "data": {
                    ".dockerconfigjson": "$${dockerconfigjson64}"
                  }
              }
              EOF

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: harbor-token-generator-role
  namespace: jenkins
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: harbor-token-generator-rolebinding
  namespace: jenkins
subjects:
  - kind: ServiceAccount
    name: harbor-token-generator
    namespace: jenkins
roleRef:
  kind: Role
  name: harbor-token-generator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: harbor-token-generator
  namespace: jenkins
