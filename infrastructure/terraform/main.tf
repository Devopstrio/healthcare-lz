provider "azurerm" {
  features {}
}

# --- Clinical Governance Foundation ---

resource "azurerm_resource_group" "health" {
  name     = "rg-${var.project_name}-foundation-${var.environment}"
  location = var.location
}

# --- Regulated Clinical Network ---

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.project_name}-hub-${var.environment}"
  location            = azurerm_resource_group.health.location
  resource_group_name = azurerm_resource_group.health.name
  address_space       = ["10.220.0.0/16"]

  tags = {
    Environment = var.environment
    CostCenter  = "Clinical-Foundation"
    HIPAA       = "Compliant"
  }
}

# --- Governance Data Store (Postgres) ---

resource "azurerm_postgresql_flexible_server" "health" {
  name                   = "psql-${var.project_name}-config-${var.environment}"
  resource_group_name    = azurerm_resource_group.health.name
  location               = azurerm_resource_group.health.location
  version                = "13"
  administrator_login    = "healthadmin"
  administrator_password = var.db_password
  storage_mb             = 131072
  sku_name               = "GP_Standard_D4ds_v4"
}

# --- Clinical Identity Secrets (KeyVault) ---

resource "azurerm_key_vault" "health" {
  name                = "kv-${var.project_name}-secrets-${var.environment}"
  location            = azurerm_resource_group.health.location
  resource_group_name = azurerm_resource_group.health.name
  tenant_id           = var.tenant_id
  sku_name            = "premium"

  purge_protection_enabled = true
}

# --- PHI Data Audit Archive (Storage) ---

resource "azurerm_storage_account" "audit" {
  name                     = "st${var.project_name}audit${var.environment}"
  resource_group_name      = azurerm_resource_group.health.name
  location                 = azurerm_resource_group.health.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
