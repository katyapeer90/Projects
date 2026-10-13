variable "environment" {
  type        = string
}   

variable "region" {
  type        = string
}

#variable "service_cidr" {
#  type       = string
#}
#
#variable "dns_service_ip" {
#  type       = string
#}

variable "kubernetes_version" {
  type        = string
}

variable "aks_resource_group_name" {
  type        = string
  
}

# variable "azure_ad_admin_group_id" {
#   type      = string
# }

variable "linuxapp_vm_size" {
  type        = string
}

variable "linuxapp_node_count" {
  type        = number
}

variable "msapp_vm_size" {
  type        = string
}

variable "msapp_node_count" {
  type        = number
}

variable "linuxspot_vm_size" {
  type        = string
}

variable "linuxspot_node_count" {
  type        = number
}

variable "linuxspot2_vm_size" {
  type        = string
}

variable "linuxspot2_node_count" {
  type        = number
}

variable "acr_id" {
  type        = string
}

variable "system_node_count" {
  type        = number
}

variable "system_vm_size" {
  type        = string
}

#variable "subnet_prefixes" {
#  type       = list(string)
#}

#variable "address_space" {
#  type       = list(string)
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

variable "subscription_id" {
  description = "the id of the subscription"
  type        = string
  
}

variable "vnet_resource_group_name" {
  description = "The name of the resource group for the existing Virtual Network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the existing Subnet"
  type        = string
}
variable "subnet_id" {
  description = "The ID of the existing Subnet"
  type        = string
  
}

variable "aks_api_authorized_ip_ranges" {
  description = "List of CIDR blocks that are allowed to access the AKS API server"
  type        = list(string)
  default     = []  # You can set a default or require this to be set when applying
}

variable "vnet_name" {
  description = "The name of the existing Virtual Network"
  type        = string 
}

variable "vnet_id" {
  description = "The ID of the existing Virtual Network"
  type        = string
}

#variable "nsg_inbound_rules" {
#  type = list(object({
#    name                       = string
#    priority                   = number
#    direction                  = string
#    access                     = string
#    protocol                   = string
#    source_port_range          = string
#    destination_port_range     = string
#    source_address_prefix      = string
#    destination_address_prefix = string
#  }))
#  default = []
#}
