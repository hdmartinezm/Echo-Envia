# Backend configuration para almacenar el state en Azure Storage
# Descomentar y configurar después de crear el Storage Account para el state

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "tfstateenvia"
#     container_name       = "tfstate"
#     key                  = "envia.terraform.tfstate"
#   }
# }

# Para crear el backend storage, ejecutar:
# az group create --name rg-terraform-state --location "East US"
# az storage account create --name tfstateenvia --resource-group rg-terraform-state --location "East US" --sku Standard_LRS
# az storage container create --name tfstate --account-name tfstateenvia

# Trigger workflow execution
