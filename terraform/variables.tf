variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "rg-datalake-terraform"
}

variable "storage_account_name" {
  default = "datalaketfexample"  # Must be globally unique
}
