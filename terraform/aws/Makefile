SHELL := /bin/bash

# Set environment variables for AWS
export AWS_PROFILE ?= default
export AWS_REGION ?= eu-central-1

GRAY := $(shell echo -e "\033[1;30m")
LIGHT_GREEN := $(shell echo -e "\033[1;32m")
LIGHT_BLUE := $(shell echo -e "\033[0;34m")
BACK_RED := $(shell echo -e "\033[1;31m")
NC := $(shell echo -e "\033[0m") # No Color


# Terraform commands
.PHONY: init apply setup

init:
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

destroy:
	@echo "Executing terraform destroy..."
	@terraform destroy -auto-approve


