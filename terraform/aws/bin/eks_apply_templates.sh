#!/usr/bin/env bash

set -eu

source ._make_overrides || true

green_text="\033[1;32m"
normal_text="\033[0m"

login_to_eks () {
    aws eks --region $AWS_REGION update-kubeconfig --name $TF_VAR_stack_name
}

install_flux() {
  echo -e "${green_text}Adding Flux to the Helm Roster and Upgrading to the Hardcoded Magickal Version! 🪄🌟${normal_text}"
  helm repo add flux-community https://fluxcd-community.github.io/helm-charts
  helm upgrade --history-max 5 --create-namespace -n flux-system --install flux2 flux-community/flux2 --version 2.10.0 --values ../../user-data/manifests/values-flux2.yaml
}

create_ns() {
  echo -e "${green_text}Creating Kingdoms for stuff in the Kubernetes Realm! 🏰🌐${normal_text}"
  for ns in monitoring security registry jenkins karpenter; do
    kubectl create namespace ${ns} || true
  done
}

customize_eks() {
  # Set gp2 as non-default storage class
  echo -e "${green_text}De-Throning the Default Storage Class${normal_text}"
  kubectl annotate sc gp2 storageclass.kubernetes.io/is-default-class-

  # https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
  echo -e "${green_text}Unleashing the Power of Pods: Boosting Node Capacity with Prefix Delegation! 🚀🌐${normal_text}"
  kubectl set env daemonset aws-node -n kube-system DISABLE_TCP_EARLY_DEMUX=true
  kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
  kubectl set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1
  kubectl set env daemonset aws-node -n kube-system WARM_IP_TARGET=8
  kubectl set env daemonset aws-node -n kube-system MINIMUM_IP_TARGET=7

  # kubectl scale -n kube-system --replicas=${COREDNS_REPLICAS} deployment/coredns
  # kubectl set image daemonset.apps/kube-proxy -n kube-system kube-proxy=${KUBE_PROXY_IMAGE}
  # kubectl set image deployment.apps/coredns -n kube-system coredns=${COREDNS_IMAGE}
}


tf_render_eks_templates () {
  echo -e "${green_text}Crafting Magic YAML Potions with Terraform and Templates! ✨📜✨${normal_text}"
  mkdir -p .TemporaryItems
  temp_file=$(mktemp)
  terraform output -json templates > ${temp_file}
  for template in ./../../user-data/templates/*.tpl; do
    expected_file=$(basename ${template%.tpl}.yaml)
    template_file=$(basename ${template})
    cat ${temp_file} |  jq -r --arg template_file "${template_file}" '.[$template_file].yaml' > .TemporaryItems/${expected_file}
  done
}

apply_external_manifests() {
  echo -e "${green_text}Evolving the Kubernetes Ecosystem with External Manifests! 🌱🚀${normal_text}"
  terraform output -json external_manifests | jq -r '.[]'
  for manifest in $(terraform output -json external_manifests | jq -r '.[]'); do
    kubectl apply -f ${manifest}
  done
}

kubectl_batch () {
  action=$1
  echo -e "${green_text}Doing things with Kubernetes Manifests from the Mystic YAML Scrolls! 🧙‍♂️✨${normal_text}"
  for manifest in .TemporaryItems/*.yaml; do
    if [[ " kube-system-cert-manager-main.yaml " =~ $manifest ]] ; then
      echo "Waiting for CRD to appear" && speep 2
    fi
    kubectl ${action} -f ${manifest} --
  done
}

login_to_eks
create_ns
apply_external_manifests
install_flux
customize_eks
tf_render_eks_templates
kubectl_batch apply