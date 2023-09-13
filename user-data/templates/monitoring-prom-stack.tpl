---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: prometheus-community
  namespace: monitoring
spec:
  interval: 60m
  url: https://prometheus-community.github.io/helm-charts
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: grafana
  namespace: monitoring
spec:
  interval: 60m
  url: https://grafana.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: promstack
  namespace: monitoring
spec:
  suspend: false
  interval: 5m
  # releaseName: kube-prometheus-stack
  install:
    remediation:
      retries: -1
    timeout: 20m
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  chart:
    spec:
      chart: kube-prometheus-stack
      version: ${version_helm_promstack}
      sourceRef:
        kind: HelmRepository
        name: prometheus-community
        namespace: monitoring
      interval: 10m
  values:
    grafana:
      defaultDashboardsEnabled: false
      ingress:
        annotations:
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/scheme: internet-facing
          # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
          alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
          alb.ingress.kubernetes.io/group.name: mgmt
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/tags: "promstack=true"
          alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
          alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
          cert-manager.io/cluster-issuer: "letsencrypt-staging"
        enabled: true
        hosts: [grafana.${stack_name}.${domain_name}]
        path: /
      plugins:
      - grafana-piechart-panel
      datasources:
        defaultDatasourceEnabled: false
        datasources.yaml:
          apiVersion: 1
          datasources:
          - name: Loki
            type: loki
            url: 'http://loki:3100'
            jsonData:
              httpHeaderName1: 'X-Scope-OrgID'
            secureJsonData:
              httpHeaderValue1: '1'
            # orgId: 1
            access: proxy
          - name: Prometheus
            type: prometheus
            uid: prometheus
            url: http://promstack-kube-prometheus-prometheus.monitoring:9090/
            access: proxy
            # isDefault: true
            jsonData:
              timeInterval: 30s
      grafana.ini:
        security:
          disable_initial_admin_creation: true
        users:
          viewers_can_edit: true
          editors_can_admin: true
        auth:
          disable_login_form: true
          disable_signout_menu: true
        auth.anonymous:
          enabled: true
          org_role: Admin
        dashboards:
          default_home_dashboard_path: /var/lib/grafana/dashboards/default/new-global.json
          # default_home_dashboard_path: /var/lib/grafana/dashboards/default/home-dashboard-eks-monitoring.json
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
          - name: 'custom'
            orgId: 1
            folder: ''
            type: file
            disableDeletion: false
            editable: true
            options:
              path: /var/lib/grafana/dashboards/default
      dashboards:
        default:
          node-exporter-full:
            gnetId: 1860
            datasource: Prometheus
            revision: latest
          k8s-nginx-ingress-nextgen:
            gnetId: 14314
            datasource: Prometheus
            revision: latest
          k8s-overview:
            gnetId: 7249
            datasource: Prometheus
            revision: latest
          k8s-nginx-ingress:
            # gnetId: 9614
            url: https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json
            datasource: Prometheus
          k8s-storage-monitoring:
            gnetId: 11454
            datasource: Prometheus
            revision: latest
          cilium-op:
            gnetId: 16612
            datasource: Prometheus
            revision: latest
          cilium-ag:
            gnetId: 16611
            datasource: Prometheus
            revision: latest
          loki-monitoring:
            datasource: Prometheus
            gnetId: 13407
            revision: latest
          net-coredns:
            datasource: Prometheus
            gnetId: 15762
            revision: latest
          new-global:
            datasource: Prometheus
            gnetId: 15757
            revision: latest
          new-namespaces:
            datasource: Prometheus
            gnetId: 15758
            revision: latest
          new-nodes:
            datasource: Prometheus
            gnetId: 15759
            revision: latest
          new-pods:
            datasource: Prometheus
            gnetId: 15760
            revision: latest
          jenkins:
            datasource: Prometheus
            gnetId: 9964
            revision: latest
      serviceMonitor:
        labels:
          release: "promstack"
    prometheusOperator:
      resources:
        limits:
          cpu: 50m
          memory: 64Mi
      prometheusConfigReloader:
        resources:
          requests:
            cpu: 20m
            memory: 25Mi
    prometheus:
      ingress:
        enabled: true
        annotations:
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/scheme: internet-facing
          # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
          alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
          alb.ingress.kubernetes.io/group.name: mgmt
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/tags: "promstack=true"
          alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
          alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
          alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
          cert-manager.io/cluster-issuer: "letsencrypt-staging"
        hosts: [prometheus.${stack_name}.${domain_name}]
      prometheusSpec:
        # nodeSelector:
        #   "kubernetes.io/arch": arm64
        retention: 3d
        retentionSize: ""
        storageSpec:
          volumeClaimTemplate:
            spec:
              # storageClassName: local-path
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  cpu: "100m"
                  storage: 2Gi
    alertmanager:
      alertmanagerSpec:
        resources:
          requests:
            cpu: "10m"
            memory: "32Mi"
    defaultRules:
      create: true
      rules:
        alertmanager: true
        etcd: false
        configReloaders: true
        general: true
        k8s: true
        kubeApiserverAvailability: true
        kubeApiserverBurnrate: true
        kubeApiserverHistogram: true
        kubeApiserverSlos: true
        kubeControllerManager: true
        kubelet: true
        kubeProxy: true
        kubePrometheusGeneral: true
        kubePrometheusNodeRecording: true
        kubernetesApps: true
        kubernetesResources: true
        kubernetesStorage: true
        kubernetesSystem: true
        kubeSchedulerAlerting: true
        kubeSchedulerRecording: true
        kubeStateMetrics: true
        network: true
        node: true
        nodeExporterAlerting: true
        nodeExporterRecording: true
        prometheus: true
        prometheusOperator: true
        windows: true
