resource "azurerm_virtual_network" "this_vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this_rg.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this_rg.name
  tags                = local.tags
}

resource "azurerm_subnet" "this_subnet_1" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "${module.naming.subnet.name_unique}-1"
  resource_group_name  = azurerm_resource_group.this_rg.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
}

resource "azurerm_subnet" "this_subnet_2" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "${module.naming.subnet.name_unique}-2"
  resource_group_name  = azurerm_resource_group.this_rg.name
  virtual_network_name = azurerm_virtual_network.this_vnet.name
}

resource "azurerm_network_security_group" "blank_nsg" {
  location            = azurerm_resource_group.this_rg.location
  name                = "nsg-blank"
  resource_group_name = azurerm_resource_group.this_rg.name
}

resource "azurerm_subnet_network_security_group_association" "remote_office" {
  network_security_group_id = azurerm_network_security_group.blank_nsg.id
  subnet_id                 = azurerm_subnet.this_subnet_1.id
}