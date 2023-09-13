apiVersion: batch/v1
kind: Job
metadata:
  name: defectdojo-jenkins-token
  namespace: jenkins
spec:
  template:
    spec:
      serviceAccountName: defectdojo-token-generator
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

              host=defectdojo.${domain_name}
              svc=defectdojo-django.security.svc.cluster.local
              password='qwer12#34QWER'
              # Waiting for harbor to come up
              while ! (curl  -S --fail-with-body http://$${svc}/api/v2/api-token-auth/ --connect-timeout 5 \
              -H "Host: $${host}" -X POST --data '{"username": "admin", "password": "admin"}' -H 'Content-Type: application/json'); \
              do echo "Defectdojo yet not responsive ($${x:=1})..."; let x++; sleep 5; done

              sleep 30
              # Get admin token
              admin_token=$(curl -sk "http://$${svc}/api/v2/api-token-auth/" -H "Host: $${host}" -X POST \
                -H 'accept: application/json' \
                -H 'Content-Type: application/json' \
              --data '{"username": "admin", "password": "admin"}' | jq -r '.token')
              echo admin_token=$${admin_token}
              # # Create product
              curl -sk "http://$${svc}/api/v2/products/" -H "Host: $${host}" -X POST \
                -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Token $${admin_token}" \
                --data '{
                  "tags": ["java","web"],
                  "name": "Application",
                  "description": "Test application",
                  "prod_type": 1,
                  "enable_simple_risk_acceptance": true,
                  "enable_full_risk_acceptance": false
                }' | jq

              curl -sk "http://$${svc}/api/v2/products/" -H "Host: $${host}" -X GET \
                -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Token $${admin_token}" | jq

              # Create endpoint
              curl -sk "http://$${svc}/api/v2/endpoints/" -H "Host: $${host}" -X POST \
                -H 'accept: application/json' \
                -H 'Content-Type: application/json' \
                -H "Authorization: Token $${admin_token}" \
                --data '{
                  "tags": [
                    "generic"
                  ],
                  "host": "127.0.0.1",
                  "path": "/",
                  "product": 1
                }'

              curl -sk "http://$${svc}/api/v2/endpoints/" -H "Host: $${host}" -X GET \
                -H 'accept: application/json' -H 'Content-Type: application/json' -H "Authorization: Token $${admin_token}" | jq

              # Create automate user
              curl -sk "http://$${svc}/api/v2/users/" -H "Host: $${host}" -X POST \
                -H 'accept: application/json' \
                -H 'Content-Type: application/json' \
                -H "Authorization: Token $${admin_token}" \
              --data '{
                "username": "automate",
                "first_name": "Auto",
                "last_name": "Mation",
                "email": "auto@${domain_name}",
                "is_active": true,
                "is_superuser": true,
                "password": "'"$${password}"'"
              }'

              # Get automate token
              automation_token=$(curl -sk "http://$${svc}/api/v2/api-token-auth/" -H "Host: $${host}" -X POST \
                -H 'accept: application/json' \
                -H 'Content-Type: application/json' \
                --data '{"username": "automate", "password": "'"$${password}"'"}' | jq -r '.token')
              echo "automation_token=$${automation_token}"
              token64=$(echo -n "$${automation_token}"| base64 -w0)

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
                    "name": "defectdojo-token",
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
  name: defectdojo-token-generator-role
  namespace: jenkins
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: defectdojo-token-generator-rolebinding
  namespace: jenkins
subjects:
  - kind: ServiceAccount
    name: defectdojo-token-generator
    namespace: jenkins
roleRef:
  kind: Role
  name: defectdojo-token-generator-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: defectdojo-token-generator
  namespace: jenkins
