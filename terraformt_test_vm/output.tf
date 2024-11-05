data "azurerm_subscription" "current" {
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
}

output "resource_group_name" {
  value = azurerm_resource_group.this_rg.name
  
}

output "virtual_machine_name" {
  value = module.testvm.name
  
}