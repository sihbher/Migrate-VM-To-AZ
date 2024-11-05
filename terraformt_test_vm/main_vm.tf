module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}


locals {
  tags = {
    scenario = "windows_w_data_disk_and_public_ip"
    delete = "yes"
  }
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions_by_name) - 1
  min = 0
}

module "get_valid_sku_for_deployment_region" {
  source = "./modules/sku_selector"

  deployment_region = module.regions.regions[random_integer.region_index.result].name
}

module "testvm" {
  source = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.15.1"

  enable_telemetry    = true
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  os_type             = "Windows"
  name                = module.naming.virtual_machine.name_unique
  sku_size            = module.get_valid_sku_for_deployment_region.sku
  zone                = null

  generated_secrets_key_vault_secret_config = {
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-g2"
    version   = "latest"
  }

  network_interfaces = {
    network_interface_1 = {
      name = module.naming.network_interface.name_unique
      ip_configurations = {
        ip_configuration_1 = {
          name                          = "${module.naming.network_interface.name_unique}-ipconfig1"
          private_ip_subnet_resource_id = azurerm_subnet.this_subnet_1.id
          create_public_ip_address      = true
          public_ip_address_name        = module.naming.public_ip.name_unique
        }
      }
    }
  }

  # data_disk_managed_disks = {
  #   disk1 = {
  #     name                 = "${module.naming.managed_disk.name_unique}-lun0"
  #     storage_account_type = "Premium_LRS"
  #     lun                  = 0
  #     caching              = "None"
  #     disk_size_gb         = 32
  #     max_shares           = 2
  #     tier                 = "P20"
  #   }
  # }

  # shutdown_schedules = {
  #   test_schedule = {
  #     daily_recurrence_time = "1700"
  #     enabled               = true
  #     timezone              = "Pacific Standard Time"
  #     notification_settings = {
  #       enabled         = true
  #       email           = "example@example.com;example2@example.com"
  #       time_in_minutes = "15"
  #       webhook_url     = "https://example-webhook-url.example.com"
  #     }
  #   }
  # }

  tags = local.tags

  depends_on = [
    module.avm_res_keyvault_vault
  ]
}