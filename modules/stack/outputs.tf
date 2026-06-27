output "resource_group_name" {
  description = "Name of the environment resource group."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = module.vnet.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = module.vnet.subnet_ids
}

output "storage_account_name" {
  description = "Name of the storage account (null when enable_storage = false)."
  value       = one(azurerm_storage_account.this[*].name)
}

output "blob_container_name" {
  description = "Name of the blob container (null when enable_storage = false)."
  value       = one(azurerm_storage_container.this[*].name)
}

output "vm_name" {
  description = "Name of the Linux VM (null when enable_vm = false)."
  value       = one(azurerm_linux_virtual_machine.this[*].name)
}

output "vm_private_ip" {
  description = "Private IP address of the VM (null when enable_vm = false)."
  value       = one(azurerm_network_interface.vm[*].private_ip_address)
}

output "vm_ssh_private_key_pem" {
  description = "Generated SSH private key for the VM (sensitive, null when enable_vm = false). For demo only; use a vault/keypair in production."
  value       = one(tls_private_key.vm[*].private_key_pem)
  sensitive   = true
}
