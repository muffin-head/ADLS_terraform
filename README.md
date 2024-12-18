Here’s a detailed explanation of the Terraform and GitHub Actions YAML files you provided, structured as a **Wiki**. The explanation will cover each part of the code, its purpose, and how everything works together.

---

## **Terraform Overview**

Terraform is an Infrastructure-as-Code (IaC) tool that allows you to define, deploy, and manage cloud infrastructure using declarative configuration files. With Terraform:
- You write configuration files in `.tf` format.
- Terraform uses these files to create, update, or delete cloud resources.

### **Main Components of Terraform**

1. **Provider**:
   - Specifies the cloud platform you are working with (e.g., Azure, AWS, GCP).
   - In this case, `azurerm` is the Azure provider.

2. **Resources**:
   - Define the specific cloud services you want to create, such as resource groups, storage accounts, and containers.

3. **Variables**:
   - Allow dynamic values in your configuration for flexibility and reusability.

4. **Outputs**:
   - Provide information about the resources created, which can be referenced or displayed after deployment.

---

### **main.tf (Terraform Configuration File)**

#### **terraform { ... }**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Ensure a version >= 2.0.0
    }
  }
  required_version = ">= 1.0.0"
}
```

- **Purpose**:
   - Specifies the provider (`azurerm`) for Azure resources.
   - Ensures a compatible version of Terraform and the AzureRM provider.

- **Key Parameters**:
   - **`source`**: The namespace of the provider (e.g., `hashicorp/azurerm`).
   - **`version`**: Specifies the version of the provider to use (`~> 3.0` ensures a version in the 3.x range).

---

#### **provider { ... }**
```hcl
provider "azurerm" {
  features {}
}
```

- **Purpose**:
   - Configures the Azure provider for Terraform.
   - The `features` block is required but can remain empty.

---

#### **Resource Definitions**

##### **Resource Group**
```hcl
resource "azurerm_resource_group" "rg" {
  name     = "rg-datalake-terraform"
  location = "East US"
}
```
- **Purpose**:
   - Creates a resource group named `rg-datalake-terraform` in the `East US` region.
   - Resource groups act as containers for managing Azure resources.

---

##### **Storage Account**
```hcl
resource "azurerm_storage_account" "datalake" {
  name                     = "datalaketfexample"  # Must be globally unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  is_hns_enabled = true  # Enable Data Lake Gen2 features

  tags = {
    environment = "dev"
  }
}
```

- **Purpose**:
   - Creates an Azure Storage Account configured for **Data Lake Gen2** features (by enabling hierarchical namespaces using `is_hns_enabled = true`).

- **Key Parameters**:
   - **`name`**: A unique name for the storage account (`datalaketfexample`).
   - **`resource_group_name`**: Links the storage account to the resource group (`azurerm_resource_group.rg.name`).
   - **`is_hns_enabled`**: Enables hierarchical namespace, making the storage account compatible with Data Lake Gen2 features.
   - **`account_tier`**: Specifies the performance tier (`Standard` for cost-efficiency).
   - **`account_replication_type`**: Defines the replication strategy (`LRS` for locally redundant storage).

---

##### **Storage Containers**
```hcl
resource "azurerm_storage_container" "bronze" {
  name                  = "bronze"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}
```

- **Purpose**:
   - Creates a storage container named `bronze` for the raw data layer.
   - Similar containers (`silver`, `gold`) are created for processed and refined data.

- **Key Parameters**:
   - **`storage_account_name`**: Links the container to the storage account.
   - **`container_access_type`**: Sets the container’s access level (`private` ensures restricted access).

---

#### **Outputs**
```hcl
output "bronze_container_url" {
  value = azurerm_storage_container.bronze.id
}
```

- **Purpose**:
   - Outputs the `id` of the `bronze` container, which can be used for logging or referencing in other configurations.

---

### **variables.tf**

```hcl
variable "location" {
  default = "East US"
}
```

- **Purpose**:
   - Defines variables for dynamic values like the location or resource group name.
   - Using variables ensures flexibility and makes the code reusable.

---

### **outputs.tf**

```hcl
output "storage_account_name" {
  value = azurerm_storage_account.datalake.name
}

output "bronze_container_name" {
  value = azurerm_storage_container.bronze.name
}
```

- **Purpose**:
   - Outputs the names of the storage account and `bronze` container after Terraform applies the configuration.

---

## **GitHub Actions YAML File**

GitHub Actions automates the process of deploying infrastructure and uploading data to Azure Data Lake.

### **Workflow Triggers**
```yaml
on:
  push:
    paths:
      - "raw_data/**"    # Trigger when files in the raw_data folder change
      - "terraform/**"   # Trigger when Terraform configs change
```

- **Purpose**:
   - Triggers the workflow on any `push` to files in `raw_data` or `terraform`.

---

### **Job 1: Deploy Azure Data Lake**

```yaml
jobs:
  deploy-adls:
    name: Deploy Azure Data Lake Storage
    runs-on: ubuntu-latest
```

- **Purpose**:
   - Defines a job to deploy the Azure Data Lake using Terraform.

#### **Steps in the Job**
1. **Checkout the Repository**:
   ```yaml
   - name: Checkout repository
     uses: actions/checkout@v3
   ```

2. **Authenticate with Azure CLI**:
   ```yaml
   - name: Authenticate with Azure CLI
     run: az login --use-device-code
   ```

3. **Set Up Terraform**:
   ```yaml
   - name: Set up Terraform
     uses: hashicorp/setup-terraform@v2
     with:
       terraform_version: 1.5.6
   ```

4. **Run Terraform Commands**:
   - **Initialize**:
     ```yaml
     - name: Terraform Init
       run: terraform -chdir=terraform init
     ```
   - **Plan**:
     ```yaml
     - name: Terraform Plan
       run: terraform -chdir=terraform plan
     ```
   - **Apply**:
     ```yaml
     - name: Terraform Apply
       run: terraform -chdir=terraform apply -auto-approve
     ```

---

### **Job 2: Upload Data**

```yaml
  upload-data:
    name: Upload Data to Bronze Layer
    needs: deploy-adls
    runs-on: ubuntu-latest
```

- **Purpose**:
   - Uploads files from the `raw_data` folder to the `bronze` container.

#### **Steps in the Job**
1. **Authenticate with Azure CLI**:
   ```yaml
   - name: Authenticate with Azure CLI
     run: az login --use-device-code
   ```

2. **Upload Files**:
   ```yaml
   - name: Upload files to Bronze Layer
     run: |
       for file in raw_data/*; do
         az storage blob upload --account-name datalaketfexample --container-name bronze --file "$file" --name "$(basename "$file")"
       done
   ```

- **What’s Happening?**
   - Loops through all files in the `raw_data` folder.
   - Uploads each file to the `bronze` container in the `datalaketfexample` storage account.

---

## **Summary**

1. **Terraform**:
   - Defines Azure infrastructure (resource group, storage account, and containers).
   - Uses variables for flexibility and outputs for easy referencing.

2. **GitHub Actions**:
   - Automates Terraform deployment and uploads data to Azure.
   - Uses triggers to ensure workflows run only when necessary.

3. **Real-World Application**:
   - This setup creates a scalable Data Lake Storage system and automates data uploads for raw data ingestion.
