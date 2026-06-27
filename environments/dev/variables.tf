variable "project" {
  description = "Short project/application name."
  type        = string
  default     = "opella"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "location_short" {
  description = "Short region code used in resource names."
  type        = string
}

variable "owner" {
  description = "Owner tag value."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNET."
  type        = list(string)
}

variable "subnets" {
  description = "Subnet definitions for the environment."
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

variable "vm_subnet_name" {
  description = "Subnet to place the VM in."
  type        = string
}

variable "enable_vm" {
  description = "Whether to deploy the VM in this environment."
  type        = bool
  default     = true
}

variable "enable_storage" {
  description = "Whether to deploy the storage account in this environment."
  type        = bool
  default     = true
}
