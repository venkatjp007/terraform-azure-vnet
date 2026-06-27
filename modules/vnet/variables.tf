variable "name" {
  description = "Name of the Virtual Network."
  type        = string

  validation {
    condition     = length(var.name) > 1 && length(var.name) <= 64
    error_message = "VNET name must be between 2 and 64 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the VNET. The resource group must already exist."
  type        = string
}

variable "location" {
  description = "Azure region in which resources are created (e.g. eastus)."
  type        = string
}

variable "address_space" {
  description = "List of address spaces (CIDR blocks) for the Virtual Network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space (CIDR) must be provided."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Every entry in address_space must be a valid CIDR block."
  }
}

variable "dns_servers" {
  description = "Optional list of custom DNS servers for the VNET. Leave empty to use Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create, keyed by subnet name. For each subnet:
      - address_prefixes:   list of CIDR blocks for the subnet (required)
      - service_endpoints:  optional list of service endpoints (e.g. ["Microsoft.Storage"])
      - create_nsg:         whether to create and associate a Network Security Group (default true)
      - nsg_rules:          optional list of NSG rule objects (see below)

    NSG rule object fields:
      name, priority, direction, access, protocol,
      source_port_range, destination_port_range,
      source_address_prefix, destination_address_prefix
  EOT
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
  default = {}
}

variable "tags" {
  description = "Map of tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
