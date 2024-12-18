terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Ensure a version >= 2.0.0
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-datalake-terraform"
  location = "East US"
}

# Storage Account (ADLS Gen2)
resource "azurerm_storage_account" "datalake" {
  name                     = "datalaketfexample"  # Must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  enable_hierarchical_namespace = true  # Enable Data Lake Gen2 features

  tags = {
    environment = "dev"
  }
}

# Containers for Data Layers
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "silver" {
  name                  = "silver"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "gold" {
  name                  = "gold"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

# Outputs
output "bronze_container_url" {
  value = azurerm_storage_container.bronze.id
}
