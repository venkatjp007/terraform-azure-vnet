variable "project" {
  description = "Short project/application name used in resource naming (e.g. opella)."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, prod). Used in naming and tags."
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g. eastus)."
  type        = string
}

variable "location_short" {
  description = "Short code for the region used in resource names (e.g. eus for eastus)."
  type        = string
}

variable "owner" {
  description = "Owner tag value (team or individual responsible for the resources)."
  type        = string
}

variable "cost_center" {
  description = "Cost center / project tag for billing attribution."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the environment's Virtual Network."
  type        = list(string)
}

variable "subnets" {
  description = "Subnet definitions passed through to the vnet module (see modules/vnet)."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    create_nsg        = optional(bool, true)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
}

variable "enable_vm" {
  description = "Whether to deploy the Linux VM (and its NIC + SSH key). Set false to omit compute entirely."
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Whether to deploy the Storage Account + Blob container. Set false to omit storage entirely."
  type        = bool
  default     = true
}

variable "vm_subnet_name" {
  description = "Name of the subnet (key in var.subnets) into which the VM is deployed. Required only when enable_vm = true."
  type        = string
  default     = ""
}

variable "vm_size" {
  description = "VM SKU. Defaults to a free-tier-friendly burstable size."
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Admin username for the Linux VM."
  type        = string
  default     = "azureadmin"
}

variable "extra_tags" {
  description = "Optional additional tags merged into the standard tag set."
  type        = map(string)
  default     = {}
}
