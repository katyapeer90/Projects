terraform {
  backend "azurerm" {
    resource_group_name   = "VirtualMachines"
    storage_account_name  = "tfstate"
    container_name        = "production"
    key                   = "terraform.tfstate"
  }
}

locals {
  # tags to add to all resources
  tags     = {
    terraform             = "true",
    environment           = "test"
  }

  #set up environment unique variable
}
#module "network" {
  #source for development
#  source                 = "../CET-network-azure"
  
  #env
#  environment            = var.environment
#  tags                   = local.tags
#  region                 = var.region

  #vnet
#  address_space          = var.address_space
#  subnet_prefixes        = var.subnet_prefixes
#  existing_vnets         = var.existing_vnets

  #nsg rules
#  nsg_inbound_rules      = var.nsg_inbound_rules
#}

# Define the existing VNet and subnet
data "azurerm_virtual_network" "existing_vnet" {
  name                    = var.vnet_name
  resource_group_name     = var.vnet_resource_group_name
}

data "azurerm_subnet" "existing_subnet" {
  name                    = var.subnet_name
  virtual_network_name    = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name     = var.vnet_resource_group_name
}

module "aks-infra" {
  #source for development
  source                  = "../aks-terraform"
  
  #env
  resource_group_name     = var.aks_resource_group_name
  environment             = var.environment
  tags                    = local.tags
  region                  = var.region
  subnet_id               = var.subnet_id
  vnet_id                 = var.vnet_id
  vnet_name               = var.vnet_name
  vnet_resource_group_name = var.vnet_resource_group_name

  #vn
  #service_cidr           = var.service_cidr
  #dns_service_ip         = var.dns_service_ip

  #aks
  kubernetes_version        = var.kubernetes_version
  system_node_count         = var.system_node_count
  system_vm_size            = var.system_vm_size
  linuxapp_vm_size          = var.linuxapp_vm_size
  msapp_vm_size             = var.msapp_vm_size
  linuxapp_node_count       = var.linuxapp_node_count
  msapp_node_count          = var.msapp_node_count
  linuxspot_vm_size         = var.linuxspot_vm_size
  linuxspot_node_count      = var.linuxspot_node_count
  linuxspot2_vm_size        = var.linuxspot2_vm_size
  linuxspot2_node_count     = var.linuxspot2_node_count
  acr_id                    = var.acr_id
  min_system_node_count     = var.min_system_node_count
  max_system_node_count     = var.max_system_node_count
  min_linuxapp_node_count   = var.min_linuxapp_node_count
  max_linuxapp_node_count   = var.max_linuxapp_node_count
  min_linuxspot_node_count  = var.min_linuxspot_node_count
  max_linuxspot_node_count  = var.max_linuxspot_node_count
  min_linuxspot2_node_count = var.min_linuxspot2_node_count
  max_linuxspot2_node_count = var.max_linuxspot2_node_count
  min_msapp_node_count      = var.min_msapp_node_count
  max_msapp_node_count      = var.max_msapp_node_count
  subscription_id           = var.subscription_id
  #authorized_ip_ranges     = var.aks_api_authorized_ip_ranges

  # Ensuring AKS is destroyed before network
  #depends_on = [module.network]
  }