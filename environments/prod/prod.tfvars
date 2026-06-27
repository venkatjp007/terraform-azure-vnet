project        = "opella"
environment    = "prod"
location       = "eastus"
location_short = "eus"
owner          = "platform-team"
cost_center    = "engineering"

vnet_address_space = ["10.20.0.0/16"]

subnets = {
  app = {
    address_prefixes = ["10.20.1.0/24"]
    create_nsg       = true
    nsg_rules = [
      {
        name                   = "allow-ssh-from-vnet"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "22"
        source_address_prefix  = "VirtualNetwork"
      },
      {
        name                   = "deny-all-inbound"
        priority               = 4096
        direction              = "Inbound"
        access                 = "Deny"
        protocol               = "*"
        destination_port_range = "*"
      }
    ]
  }
  data = {
    address_prefixes  = ["10.20.2.0/24"]
    service_endpoints = ["Microsoft.Storage"]
    create_nsg        = true
  }
}

vm_subnet_name = "app"

# Optional resource toggles. Kept identical to dev so the environments stay
# parallel (both deploy a VM + storage). Flip to false to omit a resource
# entirely without touching module code.
enable_vm      = true
enable_storage = true
