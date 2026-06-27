# Native `terraform test` suite for the vnet module.
# Run with: terraform test (from modules/vnet)
#
# These use `command = plan` with a mocked azurerm provider so they assert on
# planned values without requiring real Azure credentials or creating resources.

mock_provider "azurerm" {}

variables {
  name                = "test-vnet"
  resource_group_name = "test-rg"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
      create_nsg       = true
      nsg_rules = [
        {
          name                   = "allow-ssh"
          priority               = 100
          direction              = "Inbound"
          access                 = "Allow"
          protocol               = "Tcp"
          destination_port_range = "22"
        }
      ]
    }
    data = {
      address_prefixes = ["10.0.2.0/24"]
      create_nsg       = false
    }
  }
  tags = {
    environment = "test"
  }
}

run "creates_vnet_with_expected_address_space" {
  command = plan

  assert {
    condition     = contains(azurerm_virtual_network.this.address_space, "10.0.0.0/16")
    error_message = "VNET address space did not match input."
  }
}

run "creates_one_subnet_per_input" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 2
    error_message = "Expected exactly two subnets to be planned."
  }
}

run "creates_nsg_only_for_flagged_subnets" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_group.this) == 1
    error_message = "Expected exactly one NSG (only the 'app' subnet sets create_nsg = true)."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    address_space = ["not-a-cidr"]
  }

  expect_failures = [
    var.address_space,
  ]
}
