module "regions" {
  source  = "Azure/regions/azurerm"
  version = "=0.8.1"
}

resource "azurerm_resource_group" "this_rg" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}