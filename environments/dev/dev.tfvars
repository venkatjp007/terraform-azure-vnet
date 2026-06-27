project        = "opella"
environment    = "dev"
location       = "eastus"
location_short = "eus"
owner          = "platform-team"
cost_center    = "engineering"

vnet_address_space = ["10.10.0.0/16"]

subnets = {
  app = {
    address_prefixes = ["10.10.1.0/24"]
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
      }
    ]
  }
  data = {
    address_prefixes  = ["10.10.2.0/24"]
    service_endpoints = ["Microsoft.Storage"]
    create_nsg        = true
  }
}

vm_subnet_name = "app"

# Optional resource toggles. Kept identical to prod so the environments stay
# parallel (both deploy a VM + storage). Flip to false to omit a resource
# entirely without touching module code.
enable_vm      = true
enable_storage = true
