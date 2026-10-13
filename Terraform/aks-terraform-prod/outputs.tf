output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config
  description = "Kubernetes configuration for AKS"
}

output "kube_host" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].host
  description = "Host URL for Kubernetes API"
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  description = "Client certificate for Kubernetes"
}

output "client_key" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  description = "Client key for Kubernetes"
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  description = "CA certificate for Kubernetes"
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
  description = "The name of the AKS cluster"
}

output "resource_group_name" {
  value = azurerm_kubernetes_cluster.aks.resource_group_name
  description = "The name of the resource group containing the AKS cluster"
}