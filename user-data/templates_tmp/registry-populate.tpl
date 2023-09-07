apiVersion: batch/v1
kind: Job
metadata:
  name: registry-populate
  namespace: registry
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: populate
        image: alpine:latest
        imagePullPolicy: IfNotPresent
        command:
          - sh
          - -c
          - |
              set -x
              apk add curl jq
              # Waiting for harbor to come up
              while ! (curl --fail-with-body harbor-core.registry.svc.cluster.local/api/v2.0/ping); do echo "harbor-core.registry yet not responsive..."; sleep 5; done
              sleep 10
              # Create registries
              curl -sk -X POST -u "admin:Harbor12345" http://harbor-core.registry.svc.cluster.local/api/v2.0/registries -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "name": "k8s.gcr.io",
                "url": "https://k8s.gcr.io",
                "type": "docker-registry"
              }'
              curl -sk -X POST -u "admin:Harbor12345" http://harbor-core.registry.svc.cluster.local/api/v2.0/registries -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "name": "hub.docker.com",
                "url": "https://hub.docker.com",
                "type": "docker-hub"
              }'
              curl -sk -X POST -u "admin:Harbor12345" http://harbor-core.registry.svc.cluster.local/api/v2.0/registries -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "name": "quay.io",
                "url": "https://quay.io",
                "type": "quay"
              }'

              # List registries
              curl -sk -X GET -u "admin:Harbor12345" 'http://harbor-core.registry.svc.cluster.local/api/v2.0/registries?page=1&page_size=10' -H 'accept: application/json' | jq

              # Get registry id
              docker_id=$(curl -skX 'GET' -u "admin:Harbor12345" "http://harbor-core.registry.svc.cluster.local/api/v2.0/registries?page=1&page_size=10&name=hub.docker.com" -H 'accept: application/json' | jq '.[].id')
              quay_id=$(curl -skX 'GET' -u "admin:Harbor12345" "http://harbor-core.registry.svc.cluster.local/api/v2.0/registries?page=1&page_size=10&name=quay.io" -H 'accept: application/json' | jq '.[].id')
              gcr_id=$(curl -skX 'GET' -u "admin:Harbor12345" "http://harbor-core.registry.svc.cluster.local/api/v2.0/registries?page=1&page_size=10&name=k8s.gcr.io" -H 'accept: application/json' | jq '.[].id')
              echo docker_id=$${docker_id}, quay_id=$${quay_id}, gcr_id=$${gcr_id}


              # Create projects
              curl -kX 'POST' -u "admin:Harbor12345" 'http://harbor-core.registry.svc.cluster.local/api/v2.0/projects' -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "project_name": "quay.io",
                "registry_id": '$${quay_id}',
                "public": true,
                "storage_limit": 10240000000,
                "metadata": {
                  "auto_scan": "true",
                  "public": "true"
                }
              }'

              curl -kX 'POST' -u "admin:Harbor12345" 'http://harbor-core.registry.svc.cluster.local/api/v2.0/projects' -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "project_name": "hub.docker.com",
                "registry_id": '$${docker_id}',
                "public": true,
                "storage_limit": 10240000000,
                "metadata": {
                  "auto_scan": "true",
                  "public": "true"
                }
              }'

              curl -kX 'POST' -u "admin:Harbor12345" 'http://harbor-core.registry.svc.cluster.local/api/v2.0/projects' -H 'accept: application/json' -H 'Content-Type: application/json' \
              -d '{
                "project_name": "k8s.gcr.io",
                "registry_id": '$${gcr_id}',
                "public": true,
                "storage_limit": 10240000000,
                "metadata": {
                  "auto_scan": "true",
                  "public": "true"
                }
              }'

              # List projects
              curl -skX 'GET' -u "admin:Harbor12345" "http://harbor-core.registry.svc.cluster.local/api/v2.0/projects?page=1&page_size=10" -H 'accept: application/json' | jq '.'
