
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: cert-manager
    solvers:
    # example: cross-account zone management for example.com
    # this solver uses ambient credentials (i.e. inferred from the environment or EC2 Metadata Service)
    # to assume a role in a different account
    - selector:
        dnsZones:
          - '${stack_name}.${domain_name}'
      dns01:
        cnameStrategy: Follow
        route53:
          region: '${region}'
          hostedZoneID: '${route53_zone_id}'
          # role: arn:aws:iam::YYYYYYYYYYYY:role/dns-manager
