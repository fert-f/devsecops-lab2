SHELL := /bin/bash

# Set environment variables for AWS
-include ._make_overrides
export AWS_PROFILE ?= default
export aws_iam_token_refresh ?= echo 'Do not refreshing AWS MFA tokenm assuming no-MFA version'
export AWS_REGION ?= eu-central-1
export TF_VAR_aws_region=${AWS_REGION}
export TF_VAR_stack_name ?= devsecops
export TF_VAR_domain_name ?= null


GRAY := $(shell echo -e "\033[1;30m")
LIGHT_GREEN := $(shell echo -e "\033[1;32m")
LIGHT_BLUE := $(shell echo -e "\033[0;34m")
BACK_RED := $(shell echo -e "\033[1;31m")
NC := $(shell echo -e "\033[0m") # No Color


# Terraform commands
.PHONY: apply setup eks_apply_templates

start: apply eks_apply_templates

aws_iam_token_refresh:
	@echo -e "${LIGHT_BLUE}Updating AWS MFA token...${NC}"
	@$(aws_iam_token_refresh)

init: aws_iam_token_refresh
	@echo -e "${LIGHT_BLUE}Running Terraform init step...${NC}"
	@terraform init

apply: init
	@echo -e "${LIGHT_BLUE}Executing terraform apply...${NC}"
	@terraform apply -auto-approve

output:
	@echo -e "${LIGHT_BLUE}Executing terraform output...${NC}${LIGHT_GREEN}"
	@terraform output

plan: init
	@echo "Executing terraform plan..."
	@terraform plan

kubeconfig: aws_iam_token_refresh
	@echo -e "${LIGHT_BLUE}Updating kubeconfig...${NC}"
	@aws eks --region ${AWS_REGION} update-kubeconfig --name ${TF_VAR_stack_name}

eks_apply_templates: kubeconfig
	@echo -e "${LIGHT_BLUE}Applying Kubernetes manifests...${NC}"
	@./bin/eks_apply_templates.sh || \
	  (echo -e "${BACK_RED} eks_apply_templates.sh failed. ${NC}" ; exit 1)

destroy:pre-destroy tfdestroy post-destroy

pre-destroy: aws_iam_token_refresh
	@echo -e "${LIGHT_BLUE}Destroying EKS managed resources...${NC}"
	@./bin/eks_pre_destroy.sh || \
	  (echo -e "${BACK_RED} eks_pre_destroy.sh failed. ${NC}" ; exit 1)

tfdestroy: aws_iam_token_refresh
	@echo "Executing terraform destroy..."
	@terraform destroy -auto-approve

post-destroy:
	@echo -e "${LIGHT_BLUE}Final cleanup of everything that have survived Terraform destroy...${NC}"
	@./bin/eks_post_destroy.sh || \
	  (echo -e "${BACK_RED} eks_post_destroy.sh finished with errors. ${NC}" ; exit 1)

env:
	@echo "AWS_PROFILE        = ${AWS_PROFILE}"
	@echo "AWS_REGION         = ${AWS_REGION}"
	@echo "TF_VAR_stack_name  = ${TF_VAR_stack_name}"
	@echo "TF_VAR_domain_name = ${TF_VAR_domain_name}"
