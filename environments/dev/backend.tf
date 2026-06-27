# Remote state backend (per-environment isolation).
#
# Values are intentionally left out of source control. Provide them at init
# time, e.g.:
#
#   terraform init \
#     -backend-config="resource_group_name=tfstate-rg" \
#     -backend-config="storage_account_name=opellatfstate" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=dev.terraform.tfstate"
#
# For local experimentation you can comment this block out to use local state.
terraform {
  backend "azurerm" {}
}
