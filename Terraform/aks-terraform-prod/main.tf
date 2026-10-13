data "azurerm_resource_group" "aks_rg" {
  name                      = var.resource_group_name
}

data "azurerm_virtual_network" "existing_vnet" { 
  name                      = var.vnet_name
  resource_group_name       = var.vnet_resource_group_name
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "K8s-${var.environment}"
  location                  = var.region
  resource_group_name       = data.azurerm_resource_group.aks_rg.name
  dns_prefix                = "K8s-${var.environment}"
  kubernetes_version        = var.kubernetes_version
  private_cluster_enabled   = true
  local_account_disabled    = "false"
  node_os_upgrade_channel   = "None"
  sku_tier                  = "Standard"
  #api_server_access_profile{
  #  authorized_ip_ranges = var.authorized_ip_ranges
  #}

  default_node_pool {
    name                    = "systempool"
    node_count              = var.system_node_count
    vm_size                 = var.system_vm_size
    vnet_subnet_id          = var.subnet_id
    auto_scaling_enabled    = true
    min_count               = var.min_system_node_count
    max_count               = var.max_system_node_count

    #this is configuted to match the AKS default config to not be marked as a change on every apply
   upgrade_settings {
      max_surge             = "10%"
    }
  }

  identity {
    type                    = "SystemAssigned"
  }

  #azure_active_directory_role_based_access_control {
   #azure_rbac_enabled       = true
   #tenant_id                = var.subscription_id
  #}

  network_profile {
    network_plugin          = "azure"
    network_policy          = "calico"
    #service_cidr           = var.service_cidr  
    #dns_service_ip         = var.dns_service_ip
    load_balancer_sku       = "standard"
    outbound_type           = "loadBalancer"
  }
  tags                      = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "msapp" {
  name                      = "mspool"
  kubernetes_cluster_id     = azurerm_kubernetes_cluster.aks.id
  vm_size                   = var.msapp_vm_size
  #node_count               = var.app_node_count
  auto_scaling_enabled       = true
  min_count                 = var.min_msapp_node_count
  max_count                 = var.max_msapp_node_count
  mode                      = "User"
  os_type                   = "Windows"
  vnet_subnet_id            = var.subnet_id
  node_labels               = {
    "app" = "OFEK" 
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "linuxspot" {
  name                      = "spotpool"
  kubernetes_cluster_id     = azurerm_kubernetes_cluster.aks.id
  vm_size                   = var.linuxspot_vm_size
  #node_count               = var.linuxspot_node_count
  auto_scaling_enabled      = true
  min_count                 = var.min_linuxspot_node_count
  max_count                 = var.max_linuxspot_node_count
  mode                      = "User"
  os_type                   = "Linux"
  priority                  = "Spot"
  vnet_subnet_id            = var.subnet_id
  node_labels               = {
    "app" = "OFEK"
    "spot" = "true" 
  }
  node_taints = [
    "spot=true:NoSchedule"
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "linuxspot2" {
  name                      = "spotpool2"
  kubernetes_cluster_id     = azurerm_kubernetes_cluster.aks.id
  vm_size                   = var.linuxspot2_vm_size
  #node_count               = var.linuxspot2_node_count
  auto_scaling_enabled       = true
  min_count                 = var.min_linuxspot2_node_count
  max_count                 = var.max_linuxspot2_node_count
  mode                      = "User"
  os_type                   = "Linux"
  priority                  = "Spot"
  vnet_subnet_id            = var.subnet_id
  node_labels               = {
    "app" = "OFEK"
    "spot" = "true" 
  }
  node_taints = [
    "spot=true:NoSchedule"
  ]
}
 resource "azurerm_role_assignment" "acr_pull" {
   scope                    = var.acr_id
   role_definition_name     = "AcrPull"
   principal_id             = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
 }

 resource "azurerm_role_assignment" "aks_subnet_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

 resource "azurerm_role_assignment" "aks_subnet_reader" {
  scope                = var.vnet_id 
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

#resource "kubernetes_namespace" "ingress_controller" {
#  metadata {
#    name = "ingress-controller"
#  }
#}

#resource "helm_release" "nginx_ingress" {
#  name       = "ort-ingress-nginx"
#  repository = "https://kubernetes.github.io/ingress-nginx"
#  chart      = "ingress-nginx"
#  version    = "4.10.0"

#  set {
#    name  = "controller.scope.enabled"
#     value = "true"
#   }

#   set {
#     name  = "controller.service.externalTrafficPolicy"
#     value = "Local"
#   }

#   set {
#     name  = "controller.service.loadBalancer.healthCheckPath"
#     value = "/healthz"
#   }

#   namespace = "default"  # Update the namespace if needed
# }

#resource "kubectl_manifest" "cluster_admin_role" {
#  yaml_body = <<-YAML
#apiVersion: rbac.authorization.k8s.io/v1
#kind: ClusterRole
#metadata:
#  name: azure-cluster-admin
#rules:
#- apiGroups: ["*"]
#  resources: ["*"]
#  verbs: ["*"]
#YAML
#}
#
#resource "kubectl_manifest" "cluster_role_binding" {
#  yaml_body = <<-YAML
#apiVersion: rbac.authorization.k8s.io/v1
#kind: ClusterRoleBinding
#metadata:
#  name: azure-cluster-admin-binding
#subjects:
#- kind: User
#  name: "${var.service_principal_app_id}"
#  apiGroup: rbac.authorization.k8s.io
#roleRef:
#  kind: ClusterRole
#  name: azure-cluster-admin
#  apiGroup: rbac.authorization.k8s.io
#YAML
#}


