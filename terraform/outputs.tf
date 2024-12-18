output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "bronze_container_name" {
  value = azurerm_storage_container.bronze.name
}
