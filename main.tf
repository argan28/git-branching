terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.18.0"
    }
  }
}

provider "azurerm" {

  alias = "sub1"
  subscription_id = var.sub_id
  tenant_id = var.tenant_id
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  provider = azurerm.sub1
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "aks_logs" {
  provider = azurerm.sub1
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_kubernetes_cluster" "aks" {
    provider = azurerm.sub1
    name                = var.aks_cluster_name
    location            = azurerm_resource_group.aks_rg.location
    resource_group_name = azurerm_resource_group.aks_rg.name
    dns_prefix          = "aksdns"

    default_node_pool {
     name       = "default"
     node_count = var.node_count
     vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }

  tags = {
    environment = "dev"
  }
}