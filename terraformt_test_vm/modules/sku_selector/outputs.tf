output "resource" {
  description = "This is a repeat of the sku value to satisfy the AVM spec requirement for a resource output."
  value       = try(local.deploy_skus[random_integer.deploy_sku.result].name, "no_current_valid_skus")
}

output "resource_id" {
  description = "This is a repeat of the sku value to satisfy the AVM spec requirement for a resource_id output."
  value       = try(local.deploy_skus[random_integer.deploy_sku.result].name, "no_current_valid_skus")
}

output "sku" {
  description = "The sku value generated by the sku selector tool"
  value       = try(local.deploy_skus[random_integer.deploy_sku.result].name, "no_current_valid_skus")
}