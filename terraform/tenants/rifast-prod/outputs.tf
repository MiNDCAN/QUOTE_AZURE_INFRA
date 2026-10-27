output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.rifast_prod.name
}

output "cluster_id" {
  value = azurerm_kubernetes_cluster.rifast_prod.id
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.rifast_prod.node_resource_group
}

output "kube_config_command" {
  description = "Run this to fetch cluster credentials"
  value       = "az aks get-credentials --subscription ${var.subscription_id} --resource-group ${azurerm_resource_group.this.name} --name ${azurerm_kubernetes_cluster.rifast_prod.name}"
}

output "oidc_issuer_url" {
  description = "Needed later to wire the workload identity federated credential during GitOps bootstrap"
  value       = azurerm_kubernetes_cluster.rifast_prod.oidc_issuer_url
}

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "backup_storage_account_name" {
  value = azurerm_storage_account.backup.name
}

output "backup_storage_connection_string" {
  description = "Feeds gitops-quote's quoteplus-postgres-backup CronJob Secret"
  value       = azurerm_storage_account.backup.primary_connection_string
  sensitive   = true
}

output "attachments_storage_account_name" {
  value = azurerm_storage_account.attachments.name
}

output "attachments_container_name" {
  value = azurerm_storage_container.attachments.name
}

output "attachments_storage_connection_string" {
  description = "Feeds quote-management-service's AZURE_STORAGE_CONNECTION_STRING via Key Vault (not committed directly, unlike stage)"
  value       = azurerm_storage_account.attachments.primary_connection_string
  sensitive   = true
}

output "workload_identity_client_id" {
  description = "Fills the workload identity client id referenced by gitops-quote's ExternalSecrets setup"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID to grant Key Vault Secrets User on the RIFAST Key Vault"
  value       = azurerm_user_assigned_identity.workload.principal_id
}
