# Managed identity used by in-cluster workloads (starting with External
# Secrets Operator) to authenticate to Azure via AKS workload identity,
# federated per workload namespace.

resource "azurerm_user_assigned_identity" "workload" {
  name                = "id-quoteplus-${var.environment}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# Every quote-* namespace in gitops-quote's RIFAST tenant - kept in sync
# with gitops-quote/values/tenants/rifast-prod/ by hand (same manual-sync
# requirement stage's own workload_identity_namespaces list has - nothing
# here auto-derives from the GitOps repo). Does NOT include quote-metabase
# (stage-only experiment, already removed from gitops-quote-mrea, no
# reason to carry into a fresh prod customer).
variable "workload_identity_namespaces" {
  description = "Namespaces whose quoteplus-workload-sa ServiceAccount can federate as the workload identity"
  type        = list(string)
  default = [
    "quote-frontend",
    "quote-framework",
    "quote-mdmservice",
    "quote-res-mdm",
    "quote-report",
    "quote-supplier",
    "quote-user-management",
    "quote-customer-management",
    "quote-language",
    "quotemanagement-service",
    "quote-distribution-list",
    "quote-redis",
    "quote-postgres",
    "quote-pgadmin",
    "quote-temporal",
    "quote-temporal-worker",
  ]
}

resource "azurerm_federated_identity_credential" "workload" {
  for_each = toset(var.workload_identity_namespaces)

  name                      = "fc-${each.value}"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
  issuer                    = azurerm_kubernetes_cluster.rifast_prod.oidc_issuer_url
  subject                   = "system:serviceaccount:${each.value}:quoteplus-workload-sa"
  audience                  = ["api://AzureADTokenExchange"]
}
