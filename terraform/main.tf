provider "azurerm" {
  client_id = var.client_id
  client_secret = var.client_secret
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id
  
  features {}
}

resource "azurerm_resource_group" "site_rg" {
  name = "site_rg"
  location = "Central India"
}

resource "azurerm_kubernetes_cluster" "site_cluster" {
  name = "site_cluster"
  resource_group_name = azurerm_resource_group.site_rg.name
  location = azurerm_resource_group.site_rg.location
  node_resource_group = "site_node_rg"
  dns_prefix = "site"
  sku_tier = "Free"

  default_node_pool {
    name = "default"
    node_count = 2
    auto_scaling_enabled = false
    # Cheapest vm... but arm cpu...
    vm_size = "Standard_B2pls_v2"
    os_disk_size_gb = "32"
    os_disk_type = "Managed"
    os_sku = "Ubuntu"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_container_registry" "site_acr" {
  name = "siteacr"
  resource_group_name = azurerm_resource_group.site_rg.name
  location = azurerm_resource_group.site_rg.location
  sku = "Basic"
  # By default Owner role is restricted to access the acr data plane
  # Need to manually assign 'Container Registry Repository Writer' or
  # other data plan manipulation role to the user
  role_assignment_mode = "AbacRepositoryPermissions"
}

# access to acr read only
resource "azurerm_role_assignment" "site_cluster_identity_role_assignment" {
  scope = azurerm_container_registry.site_acr.id
  principal_id = azurerm_kubernetes_cluster.site_cluster.kubelet_identity[0].object_id
  role_definition_name = "Container Registry Repository Reader"
}

output "config_raw" {
  value = azurerm_kubernetes_cluster.site_cluster.kube_config_raw
  sensitive = true
}

# use the name in *.publicIPAddresses/<name> for the value in the LoadBalancer service annotation
# service.beta.kubernetes.io/azure-pip-name: <name>
output "outbound_ip_ids" {
  value = azurerm_kubernetes_cluster.site_cluster.network_profile[0].load_balancer_profile[0].effective_outbound_ips
}
