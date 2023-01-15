terraform {
  required_version = "~> 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.39"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

module "prerequisites" {
  source   = "../prerequisites"
  location = var.location
  name     = var.name
  tags     = var.tags
}

# This keyvault is NOT firewalled.
resource "azurerm_key_vault" "example" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = module.prerequisites.resource_group_name
  enable_rbac_authorization = true

  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  sku_name = "standard"

  tags = var.tags
}

locals {
  role_assignements = [
    {
      principal : "69e8ee33-8ac0-49bd-9715-969dbb75a4ff" # bastian-nolte_outlook.de#EXT#@istademo.onmicrosoft.com
      role : "Key Vault Administrator"
    },
    {
      principal : (module.prerequisites.managed_identity_principal_id)
      role : "Key Vault Secrets User"
    }
  ]
}
resource "azurerm_role_assignment" "example" {
  count                = length(local.role_assignements)
  scope                = azurerm_key_vault.example.id
  role_definition_name = local.role_assignements[count.index].role
  principal_id         = local.role_assignements[count.index].principal
}

resource "azurerm_key_vault_certificate" "example" {
  name         = "nginx-on-azure-terraform-demo1"
  key_vault_id = azurerm_key_vault.example.id

  certificate {
    contents = filebase64("nginx-on-azure-terraform-demo1.bergsee.consulting.pfx")
    password = ""
  }

  depends_on = [
    azurerm_role_assignment.example
  ]
}

resource "azurerm_nginx_deployment" "example" {
  name                     = var.name
  resource_group_name      = module.prerequisites.resource_group_name
  sku                      = var.sku
  location                 = var.location
  diagnose_support_enabled = false

  identity {
    type         = "UserAssigned"
    identity_ids = [module.prerequisites.managed_identity_id]
  }

  frontend_public {
    ip_address = [module.prerequisites.public_ip_address_id]
  }
  network_interface {
    subnet_id = module.prerequisites.subnet_id
  }

  tags = var.tags
}

resource "azurerm_nginx_certificate" "example" {
  name                     = var.name
  nginx_deployment_id      = azurerm_nginx_deployment.example.id
  key_virtual_path         = "/etc/nginx/ssl/nginx-on-azure-terraform-demo1.key"
  certificate_virtual_path = "/etc/nginx/ssl/nginx-on-azure-terraform-demo1.crt"
  key_vault_secret_id      = azurerm_key_vault_certificate.example.secret_id
}

resource "azurerm_nginx_configuration" "example" {
  nginx_deployment_id = azurerm_nginx_deployment.example.id
  root_file           = "/etc/nginx/nginx.conf"

  config_file {
    content      = filebase64("${path.module}/nginx.conf")
    virtual_path = "/etc/nginx/nginx.conf"
  }

  config_file {
    content      = filebase64("${path.module}/api.conf")
    virtual_path = "/etc/nginx/site/api.conf"
  }

  depends_on = [
    azurerm_nginx_certificate.example
  ]
}
