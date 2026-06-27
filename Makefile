.PHONY: help fmt validate lint sec test docs plan-dev plan-prod

ENV ?= dev

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "\033[36m%-12s\033[0m %s\n",$$1,$$2}'

fmt: ## Format all Terraform files
	terraform fmt -recursive

validate: ## Validate all modules and environments
	@for dir in modules/vnet modules/stack environments/dev environments/prod; do \
		echo "== validate $$dir =="; \
		terraform -chdir=$$dir init -backend=false >/dev/null && \
		terraform -chdir=$$dir validate; \
	done

lint: ## Run tflint recursively
	tflint --init && tflint --recursive --config=$(PWD)/.tflint.hcl

sec: ## Run tfsec security scan
	tfsec .

test: ## Run native terraform tests for the vnet module
	cd modules/vnet && terraform init -backend=false && terraform test

docs: ## Regenerate terraform-docs for the vnet module
	terraform-docs markdown table --output-file README.md modules/vnet

plan-%: ## Plan an environment, e.g. make plan-dev (requires backend config / Azure creds)
	cd environments/$* && terraform plan -var-file=$*.tfvars
