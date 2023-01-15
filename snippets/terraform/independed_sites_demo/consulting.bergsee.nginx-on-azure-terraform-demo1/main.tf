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

locals {
  nginx_name       = "nginx-demo-tf"
  certificate_name = "consulting--bergsee--nginx-on-azure-terraform-demo1"
  # I have no idea how to get this id automatically with terraform if this resource was 
  # created in an other terraform environment because there is no corresponding data source.
  nginx_deployment_id = "/subscriptions/2343a3fa-0bf2-4ce7-94f6-5f201ad75766/resourceGroups/nginx-demo-tf/providers/Nginx.NginxPlus/nginxDeployments/nginx-demo-tf"
}

data "azurerm_key_vault" "example" {
  name                = local.nginx_name
  resource_group_name = local.nginx_name
}

resource "azurerm_key_vault_certificate" "example" {
  name         = local.certificate_name
  key_vault_id = data.azurerm_key_vault.example.id

  certificate {
    contents = filebase64("${local.certificate_name}.pfx")
    password = ""
  }
}

resource "azurerm_nginx_certificate" "example" {
  name                     = local.certificate_name
  nginx_deployment_id      = local.nginx_deployment_id
  key_virtual_path         = "/etc/nginx/ssl/${local.certificate_name}.key"
  certificate_virtual_path = "/etc/nginx/ssl/${local.certificate_name}.crt"
  key_vault_secret_id      = azurerm_key_vault_certificate.example.secret_id
}

resource "azurerm_nginx_configuration" "example" {
  nginx_deployment_id = local.nginx_deployment_id
  root_file           = "/etc/nginx/nginx.conf"

  config_file {
    content      = filebase64("${path.module}/nginx.conf")
    virtual_path = "/etc/nginx/site/${local.certificate_name}.conf"
  }

  depends_on = [
    azurerm_nginx_certificate.example
  ]
}
