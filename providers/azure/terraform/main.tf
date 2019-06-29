provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.28.0"
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "production"
  location = "West Europe"
}

#################
# NETWORK
#################

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "blue-green"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = ["10.0.0.0/16"]
}

data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

resource "azurerm_network_security_group" "sg" {
  depends_on          = ["azurerm_virtual_network.vnet"]
  name                = "sg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_network_security_rule" "blue1" {
  name                        = "blue1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "${chomp(data.http.icanhazip.body)}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.sg.name}"
}

resource "azurerm_network_security_rule" "blue2" {
  name                        = "blue2"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9000"
  source_address_prefix       = "${chomp(data.http.icanhazip.body)}/32"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.sg.name}"
}

resource "azurerm_subnet" "subnet1" {
  depends_on                = ["azurerm_network_security_group.sg"]
  name                      = "subnet1"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "10.0.0.0/23"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"
}

resource "azurerm_subnet" "subnet2" {
  name                      = "subnet2"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "10.0.2.0/23"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"
}
