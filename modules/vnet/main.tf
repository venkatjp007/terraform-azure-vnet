locals {
  # Subnets that should get an NSG created and associated.
  nsg_subnets = {
    for name, cfg in var.subnets : name => cfg if cfg.create_nsg
  }

  # Flatten NSG rules into a single map keyed by "<subnet>|<rule>" so we can
  # use a single azurerm_network_security_rule resource with for_each.
  nsg_rules = merge([
    for subnet_name, cfg in local.nsg_subnets : {
      for rule in cfg.nsg_rules :
      "${subnet_name}|${rule.name}" => merge(rule, { subnet = subnet_name })
    }
  ]...)
}

resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints
}

resource "azurerm_network_security_group" "this" {
  for_each = local.nsg_subnets

  name                = "${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.nsg_subnets

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
