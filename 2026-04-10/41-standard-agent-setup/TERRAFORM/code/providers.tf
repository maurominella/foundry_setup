# Setup providers
provider "azapi" {
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
  storage_use_azuread = true
}