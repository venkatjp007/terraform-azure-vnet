output "vnet_id" {
  description = "The resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space (CIDR blocks) of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name to its address prefixes."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.address_prefixes }
}

output "nsg_ids" {
  description = "Map of subnet name to associated Network Security Group ID (only for subnets with create_nsg = true)."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}
