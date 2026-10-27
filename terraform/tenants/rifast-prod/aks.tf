resource "azurerm_kubernetes_cluster" "rifast_prod" {
  name                = var.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "aks-quoteplus-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "systempool"
    vm_size        = var.system_node_vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    auto_scaling_enabled = true
    min_count            = var.system_node_min_count
    max_count            = var.system_node_max_count
    node_count           = var.system_node_min_count
    os_disk_size_gb      = 128

    # Keeps this pool for CoreDNS, metrics-server, CSI drivers and the
    # Cilium operator only; app workloads land on the "apppool" pool.
    only_critical_addons_enabled = true

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  # Enabled up front so the GitOps bootstrap (workload identity, ESO) has
  # what it needs without a second cluster update later.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    load_balancer_sku   = "standard"
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "apppool" {
  name                  = "apppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.rifast_prod.id
  vm_size               = var.general_node_vm_size
  vnet_subnet_id        = azurerm_subnet.aks.id
  mode                  = "User"

  auto_scaling_enabled = true
  min_count            = var.general_node_min_count
  max_count            = var.general_node_max_count
  node_count           = var.general_node_min_count
  os_disk_size_gb      = 128

  tags = var.tags
}
