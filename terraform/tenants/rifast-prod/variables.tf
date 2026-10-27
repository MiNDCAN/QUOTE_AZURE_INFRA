variable "subscription_id" {
  description = "Azure subscription ID - Mindcan Production (shared with ProfitPlus; QuotePlus is a separate product there, no relation to those clusters)"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment/tenant label for this cluster"
  type        = string
  default     = "rifast-prod"
}

variable "resource_group_name" {
  description = "Resource group for RIFAST's dedicated QuotePlus production AKS cluster and its network"
  type        = string
  default     = "Rifast_QuotePlus_Prod_rg"
}

variable "cluster_name" {
  description = "Name of RIFAST's dedicated QuotePlus production AKS cluster"
  type        = string
  default     = "Rifast_QuotePlus_Prod"
}

variable "kubernetes_version" {
  description = "Kubernetes version to pin the cluster to. Leave null to use the current AKS default."
  type        = string
  default     = null
}

# --- Networking ---------------------------------------------------------
# Reserved from 10.200.0.0/12 - the address block set aside for the whole
# QuotePlus production fleet (one /16 per customer: RIFAST is the first,
# 10.200.0.0/16; the next customer gets 10.201.0.0/16, and so on). Chosen
# deliberately non-overlapping so hub-spoke VNet peering stays possible
# later without renumbering - but customer VNets should only ever peer to
# a future shared hub, never directly to each other (that would break the
# whole point of a dedicated, isolated customer environment). Not
# coordinated with ProfitPlus's VNets in this same subscription - different
# product, never intended to connect to these.

variable "vnet_address_space" {
  description = "VNet address space - first /16 in the QuotePlus production fleet's reserved 10.200.0.0/12 block"
  type        = list(string)
  default     = ["10.200.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "AKS node subnet"
  type        = list(string)
  default     = ["10.200.0.0/22"]
}

variable "pe_subnet_address_prefix" {
  description = "Private Endpoints subnet"
  type        = list(string)
  default     = ["10.200.4.0/24"]
}

variable "pod_cidr" {
  description = "Overlay pod CIDR (Azure CNI Overlay) - not advertised to the VNet, so safe to reuse identically across every customer cluster, same as stage"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR - same reuse-safe reasoning as pod_cidr"
  type        = string
  default     = "10.245.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP, must fall inside service_cidr"
  type        = string
  default     = "10.245.0.10"
}

# --- system node pool -----------------------------------------------------
# CoreDNS, metrics-server, CSI drivers, Cilium operator only. Autoscaling
# min 1 / max 2, Standard_D2ads_v5 - matches the org's existing node pool
# naming/sizing pattern ("systempool"/"apppool"), confirmed 2026-10-23.
# Note: default_node_pool name and vm_size both force a full AKS cluster
# replacement on change (azurerm provider constraint, not avoidable) -
# applied once, before anything is deployed to the cluster.

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2ads_v5"
}

variable "system_node_min_count" {
  type    = number
  default = 1
}

variable "system_node_max_count" {
  type    = number
  default = 2
}

# --- app node pool ------------------------------------------------
# App workloads and platform services land here - named "apppool" to match
# the org's existing pattern (was "general").

variable "general_node_vm_size" {
  type    = string
  default = "Standard_D4as_v6"
}

variable "general_node_min_count" {
  type    = number
  default = 2
}

variable "general_node_max_count" {
  type    = number
  default = 4
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name"
  type        = string
  default     = "kv-rifast-quoteplus"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "quoteplus"
    customer    = "rifast"
    environment = "rifast-prod"
    managed_by  = "terraform"
  }
}
