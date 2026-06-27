# Remote state backend (per-environment isolation).
#
# Provide values at init time, e.g.:
#
#   terraform init \
#     -backend-config="resource_group_name=tfstate-rg" \
#     -backend-config="storage_account_name=opellatfstate" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=prod.terraform.tfstate"
terraform {
  backend "azurerm" {}
}
