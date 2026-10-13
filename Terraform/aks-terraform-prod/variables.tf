variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The location/region for the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group for the AKS cluster"
  type        = string
}

variable "system_node_count" {
  description = "Node count for the system node pool"
  type        = number
}

variable "system_vm_size" {
  description = "VM size for the system node pool"
  default     = "Standard_B2ms"
  type        = string
}

variable "linuxapp_node_count" {
  description = "Node count for the application node pool"
  type        = number
}

variable "linuxapp_vm_size" {
  description = "VM size for the application node pool"
  default     = "Standard_B2ms"
  type        = string
}
variable "msapp_node_count" {
  description = "Node count for the application node pool"
  type        = number
}

variable "msapp_vm_size" {
  description = "VM size for the application node pool"
  default     = "Standard_B2ms"
  type        = string
}

variable "linuxspot_vm_size" {
  description = "VM size for the application node pool"
  default     = "Standard_B2ms"
  type        = string
}

variable "linuxspot_node_count" {
  description = "Node count for the application node pool"
  type        = number
}

variable "linuxspot2_vm_size" {
  description = "VM size for the application node pool"
  default     = "Standard_B2ms"
  type        = string
}

variable "linuxspot2_node_count" {
  description = "Node count for the application node pool"
  type        = number
}

# variable "azure_ad_admin_group_id" {
#   description = "The Azure AD group ID for AKS cluster admin access"
# }

variable "acr_id" {
  description = "The Azure Container Registry resource ID"
  type        = string
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use for the AKS cluster"
  default     = "1.29"
  type        = string
  
}

variable "subnet_id" {
  description = "The ID of the subnet where the AKS cluster will be created"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    environment = "test"
    orca        = "test"
    application = "ofek"
  }
}

#variable "service_cidr" {
#  description = "The service CIDR for the AKS cluster"
#}
#
#variable "dns_service_ip" {
#  description = "The DNS service IP for the AKS cluster"
#}

variable "min_system_node_count" {
  description = "Minimum number of nodes in the system node pool"
  type        = number
}

variable "max_system_node_count" {
  description = "Maximum number of nodes in the system node pool"
  type        = number
}

variable "min_linuxapp_node_count" {
  description = "Minimum number of nodes in the application node pool"
  type        = number
}

variable "max_linuxapp_node_count" {
  description = "Maximum number of nodes in the application node pool"
  type        = number
}

variable "min_msapp_node_count" {
  description = "Minimum number of nodes in the application node pool"
  type        = number
}

variable "max_msapp_node_count" {
  description = "Maximum number of nodes in the application node pool"
  type        = number
}

variable "min_linuxspot_node_count" {
  description = "Minimum number of nodes in the application node pool"
  type        = number
}

variable "max_linuxspot_node_count" {
  description = "Maximum number of nodes in the application node pool"
  type        = number
}

variable "min_linuxspot2_node_count" {
  description = "Minimum number of nodes in the application node pool"
  type        = number
}

variable "max_linuxspot2_node_count" {
  description = "Maximum number of nodes in the application node pool"
  type        = number
}

# variable "service_principal_app_id" {
#   description = "app id of azure service principal"
  
# }

#variable "service_principal_secret" {
#  description = "app id of azure service principal"
#  
#}

variable "subscription_id" {
  description = "the id of the subscription"
  type        = string
  
}

variable "authorized_ip_ranges" {
  description = "List of CIDR blocks that are allowed to access the AKS API server"
  type        = list(string)
  default     = []  # You can set a default or require this to be set when applying
}

variable "vnet_name" {
  description = "The name of the existing Virtual Network"
  type        = string
  
}

variable "vnet_resource_group_name" {
  description = "The name of the resource group for the existing Virtual Network"
  type        = string
  
}

variable "vnet_id" {
  description = "The ID of the existing Virtual Network"
  type        = string
  
}



