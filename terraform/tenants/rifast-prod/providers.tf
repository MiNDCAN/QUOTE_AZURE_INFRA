terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Local state to start, same as QUOTE_INFRA/terraform/stage did initially.
  # Switch to a remote backend before the real `terraform apply` against
  # production - a real paying customer's infrastructure needs a disaster-
  # recovery story local state can't give it. Bootstrap order: create a
  # small state storage account by hand (or via a one-off local-state apply
  # of just that resource) first, since Terraform can't use a backend that
  # doesn't exist yet, then uncomment below and `terraform init -migrate-state`.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-quoteplus-tfstate"
  #   storage_account_name = "stquoteplustfstate"
  #   container_name       = "tfstate"
  #   key                  = "rifast-prod.aks.tfstate"
  # }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

data "azurerm_client_config" "current" {}
