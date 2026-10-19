variable "location" {
  description = "The Azure region where resources will be deployed"
  type        = string
  default     = "eastus2"
}

variable "ai_services_name_prefix" {
  description = "Prefix for AI Foundry account name"
  type        = string
  default     = "foundry"
}

variable "project_name" {
  description = "The base name of the project; a generated unique suffix is appended"
  type        = string
  default     = "std-agent-project" # Shortened project name by mauromi
}

variable "model_name" {
  description = "The model to deploy"
  type        = string
  default     = "gpt-5.4" # Updated to the latest model version by mauromi
}

variable "model_version" {
  description = "The version of the model"
  type        = string
  default     = "2026-03-05" # Updated to the latest model version by mauromi
}

variable "model_capacity" {
  description = "The capacity of the model deployment"
  type        = number
  default     = 40
}
