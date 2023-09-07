#!/usr/bin/env bash
set -uex

source ._make_overrides || true
source bin/destroy_aws.sh


# These tags are used by the script to locate and remove AWS resources managed by EKS, ensuring that no orphaned resources are left behind.
EKSTAG=(kubernetes.io/cluster/${TF_VAR_stack_name})
EKSTAG=(kubernetes.io/cluster/${TF_VAR_stack_name})
EKSTAG_CLB=(Key=${EKSTAG},Values=owned) # Classic LB owned by k8s service
EKSTAG_ALB1=(Key=ingress.k8s.aws/cluster,Values=${TF_VAR_stack_name}) # ALB owned by k8s ingress & controller v1
EKSTAG_ALB2=(Key=elbv2.k8s.aws/cluster,Values=${TF_VAR_stack_name}) # ALB owned by k8s ingress & controller v2
NAMETAG=(Name=tag:${EKSTAG},Values=owned)
NAMETAG=(Name=tag:kubernetes/cluster/${TF_VAR_stack_name},Values=owned)

declare -a EKS_ITEM_LIST
EKS_GET_LIST=(
  "hr"
  "ingress"
  "pvc"
)

cleanup_aws() {

    echo "### Time to tidy up AWS resources! 🪣 ###"
    echo "Destroying Classic LB owned by k8s service. Say goodbye, LB! 🚀"
    TAG_FILTERS=${EKSTAG_CLB}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_LB=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:loadbalancer | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_LB $REMAINING_LB"
    destroy_elb


    echo "Unleashing the ALB-Eater on the ALB owned by k8s ingress & controller v1! 🦖💥"
    TAG_FILTERS=${EKSTAG_ALB1}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_LB=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:loadbalancer | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_LB $REMAINING_LB"
    destroy_elb


    echo "Brace yourselves, it's time to give that ALB owned by k8s ingress & controller v2 the ol' 'DELETE' treatment! 💥👋"
    TAG_FILTERS=${EKSTAG_ALB2}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_LB=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:loadbalancer | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_LB $REMAINING_LB"
    destroy_elb


    echo "It's time for the auto-scaling groups owned by EKS to meet their fate! 💥🚗"
    echo "TAG_FILTERS=${EKSTAG}"
    REMAINING_ASG=$(aws autoscaling describe-auto-scaling-groups --region ${AWS_REGION} | jq -r --arg TAG "${EKSTAG}" '.AutoScalingGroups[] | select(.Tags[] | .Key == $TAG) | .AutoScalingGroupName')
    echo "REMAINING_ASG $REMAINING_ASG"
    destroy_asg


    echo "Prepare for the grand finale as we obliterate the Target Group (TG) owned by k8s ingress & controller v1! 💥🎯"
    TAG_FILTERS=${EKSTAG_ALB1}
    REMAINING_TG=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:targetgroup | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_TG $REMAINING_TG"
    destroy_tg


    echo "Time to bid farewell to the Target Group (TG) owned by k8s ingress & controller v2. TG, it's been nice knowing you! 🎯✌️"
    TAG_FILTERS=${EKSTAG_ALB2}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_TG=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:targetgroup | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_TG $REMAINING_TG"
    destroy_tg


    echo "Launching the 'Terminate TG' mission! Say goodbye to the Target Group (TG) owned by k8s. 💥🎯"
    TAG_FILTERS=${EKSTAG_CLB}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_TG=$(aws resourcegroupstaggingapi get-resources --region ${AWS_REGION} --tag-filters ${TAG_FILTERS} \
        --resource-type-filters elasticloadbalancing:targetgroup | jq -r '.ResourceTagMappingList[] | .ResourceARN')
    echo "REMAINING_TG $REMAINING_TG"
    destroy_tg


    echo "Time to bid farewell to those EBS volumes owned by EKS! 🚀💾 Sayonara, digital storage!" 
    TAG_FILTERS=${NAMETAG}
    echo "TAG_FILTERS=${TAG_FILTERS}"
    REMAINING_VL=$(aws ec2 describe-volumes --region ${AWS_REGION} --filters ${TAG_FILTERS} | jq -r '.Volumes[] | .VolumeId')
    echo "REMAINING_VL $REMAINING_VL"
    destroy_vl


    echo "Initiating the 'Security Group Vanishing Act' for those security groups owned by EKS! 🎩🔮✨"
    TAG_FILTERS=${NAMETAG}
    REMAINING_SG=$(aws ec2 describe-security-groups --region ${AWS_REGION} --filters ${TAG_FILTERS} | jq -r '.SecurityGroups[] | .GroupId')
    echo "REMAINING_SG $REMAINING_SG"
    destroy_sg
}

login_to_eks () {
    eks_failed=false
    aws eks --region $AWS_REGION update-kubeconfig --name $TF_VAR_stack_name || (eks_failed=true ; \
      echo "Oh no, something's not quite right with updating kubeconfig for ${TF_VAR_stack_name}!")
    kubectl get nodes --no-headers | grep Ready -q || (eks_failed=true ; \
      echo "Looks like there are no ready nodes!")
    kubectl get node || (eks_failed=true ; \
      echo "Failed to uçpdate kubeconfig.")
}

cleanup_eks() {
    if [[ ${eks_failed} == true ]]; then return; fi
    for eks_type in "${EKS_GET_LIST[@]}" ; do
      echo "Deleting all ${eks_type}."
      for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
        for item in $(kubectl get ${eks_type} -n ${ns} -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
          if [[ " aws-load-balancer-controller aws-ebs-csi-driver cert-manager " =~ $item ]] ; then
            echo "Skipping protected ${eks_type}/${item}, it's got a force field of protection! 🛡️✋" && continue
          fi
          kubectl delete ${eks_type} -n ${ns} ${item} --timeout=10s || echo  "Oops! Something went wrong with deleting ${eks_type}/${item} in namespace ${ns}. But hey, at least we tried :-) ..."
        done
      done
    done
}



login_to_eks
cleanup_eks
cleanup_aws
