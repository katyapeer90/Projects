terraform {
  required_version = ">= 1.1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.3"
    }
  }
}


provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

# provider "azuread" {}
provider "kubernetes" {
  host                   = module.aks-infra.kube_host  # Consider removing if you use exec auth
  client_certificate     = base64decode(module.aks-infra.client_certificate)  # Consider removing
  client_key             = base64decode(module.aks-infra.client_key)  # Consider removing
  cluster_ca_certificate = base64decode(module.aks-infra.cluster_ca_certificate)  # Consider removing

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "az"
    args = [
      "aks",
      "get-credentials",
      "--admin",
      "--name",
      module.aks-infra.cluster_name,
      "--resource-group",
      module.aks-infra.resource_group_name,
      "--overwrite-existing"
    ]
  }
}


provider "kubectl" {
  host                   = module.aks-infra.kube_host
  client_certificate     = base64decode(module.aks-infra.client_certificate)
  client_key             = base64decode(module.aks-infra.client_key)
  cluster_ca_certificate = base64decode(module.aks-infra.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = module.aks-infra.kube_host
    client_certificate     = base64decode(module.aks-infra.client_certificate)
    client_key             = base64decode(module.aks-infra.client_key)
    cluster_ca_certificate = base64decode(module.aks-infra.cluster_ca_certificate)
  }
}

# Create the custom CoreDNS ConfigMap
resource "kubernetes_config_map" "coredns_custom" {
  metadata {
    name      = "coredns-custom"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kube-dns"
    }
  }

  }

# provider "kubernetes" {
#   host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "az"
#     args        = ["aks", "get-credentials", "--admin", "--name", azurerm_kubernetes_cluster.aks.name, "--resource-group", azurerm_kubernetes_cluster.aks.resource_group_name, "--overwrite-existing"]
#   }
# }

# provider "kubectl" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
#   }
# }

# provider "helm" {
#   kubernetes {
#     host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
#     client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
#     client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
#     cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
#   }
# }
