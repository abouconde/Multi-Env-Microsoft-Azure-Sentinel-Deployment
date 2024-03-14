provider "azurerm" {
  features {}
}

variable "name_prefix" {
  description = "Prefix for the resource names"
  type        = string
}

variable "environments" {
  description = "List of environments to deploy, e.g., ['dev', 'staging', 'prod']"
  type        = list(string)
}

variable "regions" {
  description = "List of Azure regions for deployment"
  type        = list(string)
}

variable "environment_region_map" {
  description = "Map of environments to their respective regions"
  type        = map(string)
}

# Resources for each environment in the map
resource "azurerm_resource_group" "sentinel_rg" {
  for_each = var.environment_region_map

  name     = "${var.name_prefix}-${each.key}-rg"
  location = each.value
}

resource "azurerm_log_analytics_workspace" "sentinel_workspace" {
  for_each = var.environment_region_map

  name                = "${var.name_prefix}-${each.key}-workspace"
  location            = each.value
  resource_group_name = azurerm_resource_group.sentinel_rg[each.key].name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "sentinel_solution" {
  for_each = var.environment_region_map

  solution_name         = "SecurityInsights"
  location              = each.value
  resource_group_name   = azurerm_resource_group.sentinel_rg[each.key].name
  workspace_resource_id = azurerm_log_analytics_workspace.sentinel_workspace[each.key].id
  workspace_name        = azurerm_log_analytics_workspace.sentinel_workspace[each.key].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}
