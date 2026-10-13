#complete environemnt configuration

########################################################
##########          azure Configuration         ##########
########################################################
region                       = "westeurope"
subscription_id              = ""

########################################################
##########          ENV Configuration         ##########
########################################################
environment                  = "Prod"

########################################################
##########      Networking Configuration      ##########
########################################################

vnet_name                    = ""
vnet_resource_group_name     = ""
subnet_name                  = "aks-prod"
subnet_id                    = "/subscriptions/.."
vnet_id                      = "/subscriptions/.."


#address_space               = ["10.3.0.0/16"]
#subnet_prefixes             = ["10.3.0.0/21"]

########################################################
##########           AKS Configuration        ##########
########################################################
aks_resource_group_name      = "AKS"
system_node_count            = "1"
system_vm_size               = "Standard_D4as_v5"
linuxapp_node_count          = "1"  
linuxapp_vm_size             = "Standard_D4as_v5"
msapp_node_count             = "1"
msapp_vm_size                = "Standard_D4as_v5"
linuxspot_vm_size            = "Standard_E8as_v5"
linuxspot_node_count         = "1"
linuxspot2_vm_size           = "Standard_E8as_v5"
linuxspot2_node_count        = "1"
acr_id                       = "/subscriptions/.." #located in West Europe
kubernetes_version           = "1.30.9"
min_system_node_count        = 1
max_system_node_count        = 3
min_linuxapp_node_count      = 1
max_linuxapp_node_count      = 3
min_msapp_node_count         = 1
max_msapp_node_count         = 3
min_linuxspot_node_count     = 1
max_linuxspot_node_count     = 20
min_linuxspot2_node_count    = 1
max_linuxspot2_node_count    = 20
aks_api_authorized_ip_ranges =   [""]

########################################################
##########           NSG Configuration        ##########
########################################################

# nsg_inbound_rules = [
#     {
#       name                       = "SSH"
#       priority                   = 100
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "*"
#       destination_port_range     = "22"
#       source_address_prefix      = ""
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "HTTP"
#       priority                   = 200
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "*"
#       destination_port_range     = "80"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     },
#     {
#       name                       = "HTTPS"
#       priority                   = 300
#       direction                  = "Inbound"
#       access                     = "Allow"
#       protocol                   = "Tcp"
#       source_port_range          = "*"
#       destination_port_range     = "443"
#       source_address_prefix      = "*"
#       destination_address_prefix = "*"
#     }
# ]