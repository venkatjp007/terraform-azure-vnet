module "stack" {
  source = "../../modules/stack"

  project        = var.project
  environment    = var.environment
  location       = var.location
  location_short = var.location_short
  owner          = var.owner
  cost_center    = var.cost_center

  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  vm_subnet_name     = var.vm_subnet_name
  enable_vm          = var.enable_vm
  enable_storage     = var.enable_storage
}
