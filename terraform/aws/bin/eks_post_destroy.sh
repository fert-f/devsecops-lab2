#!/usr/bin/env bash
set -uex

source ._make_overrides || true
source bin/destroy_aws.sh
source bin/r53sweep.sh

# These tags are used by the script to locate and remove AWS resources managed by EKS, ensuring that no orphaned resources are left behind.
EKSTAG=(kubernetes.io/cluster/${TF_VAR_stack_name})
EKSTAG=(kubernetes.io/cluster/${TF_VAR_stack_name})
EKSTAG_CLB=(Key=${EKSTAG},Values=owned) # Classic LB owned by k8s service
EKSTAG_ALB1=(Key=ingress.k8s.aws/cluster,Values=${TF_VAR_stack_name}) # ALB owned by k8s ingress & controller v1
EKSTAG_ALB2=(Key=elbv2.k8s.aws/cluster,Values=${TF_VAR_stack_name}) # ALB owned by k8s ingress & controller v2
NAMETAG=(Name=tag:${EKSTAG},Values=owned)
NAMETAG=(Name=tag:kubernetes/cluster/${TF_VAR_stack_name},Values=owned)

local_artifacts_cleanup() {
  echo "Deleting temporary items... Time to clean up the digital dust! 🧹"
  rm -rf .TemporaryItems
}

aws_final_clountdown() {
  echo "Time to put on our AWS detective hat 🕵️ and count ${TF_VAR_stack_name}-owned resources!"
  echo "Processing ELB, TODO..."
  echo "Processing EBS, TODO..."
  echo "Processing ASG and EC2, TODO..."
  echo "Processing Route53 records, TODO..."
  echo "Processing VPC, TODO..."
  echo "Processing ACM, TODO..."
  echo "Processing KMS, TODO..."
  echo "Processing IAM, TODO..."
  echo "Processing CloudWatch, TODO..."
  echo "Processing EKS, TODO..."
}

aws_final_cleanup() {
  echo "🧨 Brace yourselves, it's demolition time! 💥"
  echo "Now time to destroy everything that is still remaining in AWS, TODO..."
}

local_artifacts_cleanup
aws_final_clountdown
aws_final_cleanup
r53sweep