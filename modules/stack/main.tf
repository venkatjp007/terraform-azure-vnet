locals {
  # Naming convention: <project>-<env>-<region>-<resource>
  name_prefix = "${var.project}-${var.environment}-${var.location_short}"

  # Standard tag set applied to every resource. Enforced centrally so no
  # resource can be created without these tags.
  common_tags = merge({
    environment = var.environment
    region      = var.location
    owner       = var.owner
    cost_center = var.cost_center
    project     = var.project
    managed_by  = "terraform"
  }, var.extra_tags)

  # Storage account names must be globally unique, 3-24 chars, lowercase
  # alphanumeric only. `one()` yields the suffix when storage is enabled, null otherwise.
  storage_account_name = substr(
    lower(replace("${var.project}${var.environment}${var.location_short}${one(random_string.storage_suffix[*].result)}", "/[^a-z0-9]/", "")),
    0, 24
  )
}

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

module "vnet" {
  source = "../vnet"

  name                = "${local.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.common_tags
}

# ---------------------------------------------------------------------------
# Additional resource 1: Storage Account + Blob container (secure defaults)
# Toggled by var.enable_storage (count = 0 removes it entirely).
# ---------------------------------------------------------------------------
resource "random_string" "storage_suffix" {
  count = var.enable_storage ? 1 : 0

  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  count = var.enable_storage ? 1 : 0

  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.this.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}

resource "azurerm_storage_container" "this" {
  count = var.enable_storage ? 1 : 0

  name                  = "${var.environment}-data"
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Additional resource 2: Linux Virtual Machine (SSH key auth)
# Toggled by var.enable_vm (count = 0 removes it entirely).
# ---------------------------------------------------------------------------
resource "tls_private_key" "vm" {
  count = var.enable_vm ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "vm" {
  count = var.enable_vm ? 1 : 0

  name                = "${local.name_prefix}-vm-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids[var.vm_subnet_name]
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.enable_vm ? 1 : 0

  name                  = "${local.name_prefix}-vm"
  resource_group_name   = azurerm_resource_group.this.name
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.vm[0].id]
  tags                  = local.common_tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
