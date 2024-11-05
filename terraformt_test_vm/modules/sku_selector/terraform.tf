terraform {
  required_version = "~> 1.9"
  required_providers {
     azapi = {
      source  = "azure/azapi"
      version = "~> 1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.108"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}