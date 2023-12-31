---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: jenkins
  namespace: jenkins
spec:
  interval: 60m
  url: https://charts.jenkins.io
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: jenkins
  namespace: jenkins
spec:
  suspend: false
  interval: 5m
  dependsOn:
  - name: aws-load-balancer-controller
    namespace: kube-system
  - name: harbor
    namespace: registry
  install:
    timeout: 20m
    remediation:
      retries: -1
  chart:
    spec:
      chart: jenkins
      version: 4.3.24
      sourceRef:
        kind: HelmRepository
        name: jenkins
        namespace: jenkins
      interval: 10m
  values:
    controller:
      adminSecret: true
      adminUser: "admin"
      admin:
        existingSecret: "jenkins-admin"
        userKey: jenkins-admin-user
        passwordKey: jenkins-admin-password
      jenkinsUrl: http://jenkins.${stack_name}.${domain_name}/
      jenkinsAdminEmail: "jenkins@${stack_name}.${domain_name}"
      jenkinsUrlProtocol: "http"
      sidecars:
        configAutoReload:
          enabled: true
      # additionalExistingSecrets:
      #   - name: secret-credentials
      #     keyName: github_app_ro
      #   - name: secret-credentials
      #     keyName: github_devsecops_ro
      additionalSecrets:
       - name: nameOfSecret
         value: secretText
      podSecurityContextOverride:
        runAsUser: 1000
        runAsGroup: 1000
        runAsNonRoot: true
        fsGroup: 1000
      installPlugins:
        - git:5.2.0
        - git-client:4.4.0
        - configuration-as-code:1647.ve39ca_b_829b_42
        # - kubernetes:3845.va_9823979a_744
        - kubernetes:3985.vd26d77b_2a_48a_
        - blueocean:1.27.4
        - prometheus:2.2.3
        # - github:1.37.1
      additionalPlugins:
        - workflow-aggregator:581.v0c46fa_697ffd
        - pipeline-groovy-lib:656.va_a_ceeb_6ffb_f7
        - workflow-cps:3691.v28b_14c465a_b_b_
        - pipeline-rest-api:2.32
        - job-dsl:1.84
        - pipeline-model-definition:2.2131.vb_9788088fdb_5
        - cloudbees-disk-usage-simple:182.v62ca_0c992a_f3
        - cloudbees-bitbucket-branch-source:825.va_6a_dc46a_f97d
        # Locked versions to work around https://issues.jenkins.io/browse/JENKINS-70639
        - kubernetes-client-api:6.4.1-215.v2ed17097a_8e9
      imagePullPolicy: IfNotPresent
      ingress:
          enabled: true
          paths: []
          hostName: jenkins.${stack_name}.${domain_name}
          apiVersion: "networking.k8s.io/v1"
          annotations:
            kubernetes.io/ingress.class: alb
            external-dns.alpha.kubernetes.io/ttl: '120'
            alb.ingress.kubernetes.io/scheme: internet-facing
            # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
            alb.ingress.kubernetes.io/security-groups: ${sg_whitelisted}
            alb.ingress.kubernetes.io/group.name: mgmt
            alb.ingress.kubernetes.io/backend-protocol: HTTP
            alb.ingress.kubernetes.io/target-type: ip
            alb.ingress.kubernetes.io/tags: "jenkins=true"
            alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-FS-1-2-Res-2020-10"
            alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
            alb.ingress.kubernetes.io/certificate-arn: ${acm_certificate_arn}
      resources:
        limits:
          cpu: 4
          memory: 2048Mi
        requests:
          cpu: 50m
          memory: 256Mi
      JCasC:
        views:
          - all:
            name: "all"
            configScripts:
        configScripts:
          jenkins-casc-seed: |
            jobs: 
              - script: |
                  job('seed') {
                    quietPeriod(120)
                    scm {
                      git {
                        branch('fert')
                        remote {
                          github('fert-f/devsecops-lab-gitops', 'ssh')
                          credentials('github_devsecops_ro')
                        }
                      }
                    }
                  }
              - script: queue('seed')
          jenkins-casc-configs: |
            security:
              globalJobDslSecurityConfiguration:
                useScriptSecurity: false
              gitHostKeyVerificationConfiguration:
                sshHostKeyVerificationStrategy: "acceptFirstConnectionStrategy"
            # credentials:
            #   system:
            #     domainCredentials:
            #     - credentials:
            #       - string:
            #           description: "github app ro test string"
            #           id: "github_app_ro3"
            #           scope: GLOBAL
            #           secret: $${secret-credentials-github_app_ro}
            #       - basicSSHUserPrivateKey:
            #           scope: GLOBAL
            #           id: github_devsecops_ro
            #           username: fert
            #           description: "github devsecops ro token"
            #           privateKeySource:
            #             directEntry:
            #               privateKey: $${secret-credentials-github_devsecops_ro}
            #       - basicSSHUserPrivateKey:
            #           scope: GLOBAL
            #           id: github_app_ro
            #           username: fert
            #           description: "github app ro token"
            #           privateKeySource:
            #             directEntry:
            #               privateKey: $${secret-credentials-github_app_ro}
          welcome-message: |
            jenkins:
              systemMessage: Welcome to DevSecOps CI\CD server.
      prometheus:
        enabled: true
        serviceMonitorNamespace: monitoring
        serviceMonitorAdditionalLabels:
          release: "promstack"
    rbac:
      create: true
    persistence:
      # storageClass: local-path
      size: "3Gi"
      annotations:
        pv.beta.kubernetes.io/gid: "1000"

    agent:
    #   podName: default
    #   customJenkinsLabels: default
    #   # set resources for additional agents to inherit
      image: core.${stack_name}.${domain_name}:443/hub.docker.com/jenkins/inbound-agent
      tag: 3131.vf2b_b_798b_ce99-3-jdk11
      resources:
        requests:
          cpu: "100m"
          memory: "128Mi"
        limits:
          cpu: "1"
          memory: "2048Mi"

    #   volumes:
    #   - type: Secret
    #     secretName: jenkins-secrets
    #     mountPath: /var/run/secrets/jenkins-secrets