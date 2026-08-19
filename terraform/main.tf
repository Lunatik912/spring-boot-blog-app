resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

# ---------------------------------------------------------
# Existing VNet
# ---------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "spring-boot-blog-app-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "container_apps" {
  name                 = "container-apps-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "container-apps-delegation"

    service_delegation {
      name = "Microsoft.App/environments"
    }
  }

  lifecycle {
    ignore_changes = [
      delegation
    ]
  }
}

# ---------------------------------------------------------
# DEV - Azure Container Apps
# ---------------------------------------------------------

resource "azurerm_container_app_environment" "dev" {
  name                     = var.container_apps_environment_name
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  infrastructure_subnet_id = azurerm_subnet.container_apps.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

resource "azurerm_user_assigned_identity" "container_app" {
  name                = "spring-boot-blog-app-dev-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_container_app" "dev" {
  name                         = var.container_app_name
  container_app_environment_id = azurerm_container_app_environment.dev.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  depends_on = [
    azurerm_role_assignment.container_app_acr_pull
  ]

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_app.id
  }

  template {
    container {
      name   = "spring-boot-blog-app"
      image  = "${azurerm_container_registry.main.login_server}/spring-boot-blog-app:1.0"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "dev"
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = true
    target_port      = 8080

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_role_assignment" "container_app_acr_pull" {
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.main.id
}

# ---------------------------------------------------------
# AKS Network
# ---------------------------------------------------------

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ---------------------------------------------------------
# Azure Container Registry
# ---------------------------------------------------------

resource "azurerm_container_registry" "main" {
  name                = "springbootblogacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

# ---------------------------------------------------------
# UAT + PROD - AKS
# ---------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = "spring-boot-blog-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "spring-boot-blog"

  sku_tier = "Free"

  default_node_pool {
    name           = "system"
    node_count     = 1
    vm_size        = "Standard_B2s_v2"
    vnet_subnet_id = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }
}
