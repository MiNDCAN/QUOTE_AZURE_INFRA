# Storage account for the shared app Postgres's daily backup CronJob
# (gitops-quote's quoteplus-postgres-backup chart). Connection-string
# auth is still used here (same as stage) - the backup CronJob doesn't run
# as an in-cluster workload identity in gitops-quote-mrea's current design;
# revisit if that changes.

resource "azurerm_storage_account" "backup" {
  name                = "strifastquoteplusbkp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  tags = var.tags
}

resource "azurerm_storage_container" "postgres_backups" {
  name                  = "postgres-backups"
  storage_account_id    = azurerm_storage_account.backup.id
  container_access_type = "private"
}

# 7-day retention, same convention as stage - auto-deletes dump blobs older
# than 7 days so the CronJob doesn't need its own prune logic.
resource "azurerm_storage_management_policy" "backup_retention" {
  storage_account_id = azurerm_storage_account.backup.id

  rule {
    name    = "expire-postgres-backups-after-7-days"
    enabled = true

    filters {
      prefix_match = ["${azurerm_storage_container.postgres_backups.name}/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

# Customer attachment uploads (quote-management-service), the
# quoteplusstageblob/quoteplus-attachments equivalent for RIFAST - done via
# Terraform from day one, unlike stage's which was created ad hoc with
# `az storage account create` and was never added to IaC (confirmed by
# reading QUOTE_INFRA/terraform/stage/storage.tf - it only has the backup
# account above). Up to 1GB direct-from-browser uploads, so CORS needs
# GET/PUT/HEAD/OPTIONS for the real RIFAST frontend origin.
resource "azurerm_storage_account" "attachments" {
  name                = "rifastquoteplusblob"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false

  blob_properties {
    cors_rule {
      allowed_origins    = ["https://rifast-quoteplus.mindcaninc.com"]
      allowed_methods    = ["GET", "PUT", "HEAD", "OPTIONS"]
      allowed_headers    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "attachments" {
  name                  = "quoteplus-attachments"
  storage_account_id    = azurerm_storage_account.attachments.id
  container_access_type = "private"
}

# Microsoft Defender for Storage, scoped to this storage account only (not
# subscription-wide - matches the choice made for stage) - NOT managed here.
# The pinned azurerm provider version has no native
# `defenderForStorageSettings` resource, so this is applied as a follow-up
# `az rest` call against the storage account's resource ID, same PUT shape
# used for stage:
#   PUT {azurerm_storage_account.attachments.id}/providers/Microsoft.Security/defenderForStorageSettings/current?api-version=2022-12-01-preview
#   body: {"properties": {"isEnabled": true, "malwareScanning": {"onUpload": {"isEnabled": true, "capGBPerMonth": -1}}, "overrideSubscriptionLevelSettings": true}}
# Requires Microsoft.Authorization/roleAssignments/write on this resource
# group to actually enable malware scanning (the role assignment it
# auto-creates for Defender's scanning identity) - stage hit
# AuthorizationFailed here because the account applying it lacked
# Owner/User Access Administrator. Confirm that role is granted before
# running this step, so it doesn't repeat stage's partial-failure.
