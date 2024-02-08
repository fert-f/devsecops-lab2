---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: promtail
  namespace: monitoring
spec:
  suspend: false
  interval: 5m
  # releaseName: promtail
  dependsOn:
  - name: promstack
  install:
    timeout: 20m
    remediation:
      retries: -1
  chart:
    spec:
      chart: promtail
      version: ${version_helm_promtail}
      sourceRef:
        kind: HelmRepository
        name: grafana
        namespace: monitoring
      interval: 10m
  values:
    config:
      clients:
      - url: http://loki:3100/loki/api/v1/push
        tenant_id: 1
      snippets:
        extraScrapeConfigs: |
          # Add an additional scrape config for journald
          - job_name: journal
            journal:
              json: true
              path: /var/log/journal
              max_age: 12h
              labels:
                job: systemd-journal
                agent: promtail
            relabel_configs:
              - source_labels:
                  - '__journal__transport'
                target_label: 'transport'
              - source_labels:
                  - '__journal__systemd_unit'
                target_label: 'unit'
              - source_labels:
                  - '__journal__hostname'
                target_label: 'hostname'
              - source_labels:
                  - '__journal_syslog_identifier'
                target_label: 'syslog_identifier'
    positions:
      filename: /tmp/positions.yaml
    extraVolumes:
      - name: journal
        hostPath:
          path: /var/log/journal
    extraVolumeMounts:
      - name: journal
        mountPath: /var/log/journal
        readOnly: true
    resources:
      limits:
        cpu: 200m
        memory: 256Mi
      requests:
        cpu: 10m
        memory: 50Mi
    tolerations:
      - key: node.kubernetes.io/role
        operator: "Equal"
        value: controller
      - key: node.kubernetes.io/role
        operator: "Equal"
        value: worker
