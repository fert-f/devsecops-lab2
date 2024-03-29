apiVersion: batch/v1
kind: Job
metadata:
  name: sonarqube-jenkins-token
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
      serviceAccountName: sonarqube-token-generator
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

              # Install requirements
              apk add curl jq

              host=sonar.fert.name
              svc=sonarqube-sonarqube.security.svc.cluster.local:9000
              token='YWRtaW46YWRtaW4x'
              # Waiting for sonar to come up
              while ! (curl  -S --fail-with-body http://$${svc}/api/user_tokens/search --connect-timeout 5 \
              -H "Host: $${host}" -X GET -H "Authorization: Basic $${token}"); \
              do echo "Sonarqube yet not responsive ($${x:=1})..."; let x++; sleep 5; done

              sleep 5

              # Delete old admin token 
              curl -sk "http://$${svc}/api/user_tokens/revoke" \
                -H "Host: $${host}" -X POST -H "Authorization: Basic $${token}" --form 'name="main"' || true

              # Get admin token
              admin_token=$(curl -sk "http://$${svc}/api/user_tokens/generate" \
                -H "Host: $${host}" -X POST -H "Authorization: Basic $${token}" --form 'name="main"' | jq -r '.token')
              echo admin_token=$${admin_token}
              token64=$(echo -n "$${admin_token}"| base64 -w0)

              # Delete old secret
              curl -X DELETE https://kubernetes.default/api/v1/namespaces/jenkins/secrets/sonarqube-token \
                --header "Content-Type: application/json" \
                --header 'Accept: application/json' \
                --header "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
                --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt || true

              # Put automate token to kubernetes secret
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
                    "name": "sonarqube-token",
                    "namespace": "jenkins"
                  },
                  "type": "kubernetes.io/generic",
                  "data": {
                    "token": "$${token64}"
                  }
              }
              EOF

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sonarqube-token-generator-role
  namespace: jenkins
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sonarqube-token-generator-rolebinding
  namespace: jenkins
subjects:
  - kind: ServiceAccount
    name: sonarqube-token-generator
    namespace: jenkins
roleRef:
  kind: Role
  name: sonarqube-token-generator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sonarqube-token-generator
  namespace: jenkins
