variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "container_app_name" {
  description = "Name of the DEV Container App"
  type        = string
}

variable "container_apps_environment_name" {
  description = "Name of the Container Apps environment"
  type        = string
}
