output "resource_group_name" {
  description = "Resource group for the dev environment."
  value       = module.stack.resource_group_name
}

output "vnet_id" {
  description = "VNET ID."
  value       = module.stack.vnet_id
}

output "subnet_ids" {
  description = "Map of subnet name to ID."
  value       = module.stack.subnet_ids
}

output "storage_account_name" {
  description = "Storage account name."
  value       = module.stack.storage_account_name
}

output "vm_name" {
  description = "VM name."
  value       = module.stack.vm_name
}

output "vm_private_ip" {
  description = "VM private IP."
  value       = module.stack.vm_private_ip
}
