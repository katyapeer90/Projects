# Terraform - Azure Kubernetes Service (AKS) infrastructure

Terraform configurations that provision the AKS clusters and per-environment state for the CET platform. The setup uses a reusable AKS module plus one root folder per environment.

## Folder structure

```
Terraform/
├── aks-terraform/        # Reusable AKS module (dev/test clusters)
├── aks-terraform-prod/   # Reusable AKS module (production clusters - adds spot pools)
├── prep-env/             # Prep environment root (calls ../aks-terraform)
├── prod-env/             # Production environment root (calls ../aks-terraform-prod)
├── QA-env/               # QA environment root (calls ../aks-terraform)
└── test-env/             # Test environment root (calls ../aks-terraform)
```

Two layers:
- **Modules** (`aks-terraform`, `aks-terraform-prod`) - define the `azurerm_kubernetes_cluster` and node pools. No backend/provider config, only `data`/`resource`/`variable`/`output`.
- **Environment roots** (`*-env`) - each has its own `terraform backend` (separate state container), a `providers.tf`, a `terraform.tfvars`, and a `module "aks-infra"` block that sources one of the modules above.

---

## Modules

### `aks-terraform/` - dev/test AKS module

| File          | Purpose                                                                          |
| ------------- | ------------------------------------------------------------------------------- |
| `main.tf`     | The `azurerm_kubernetes_cluster` + `mspool` (Windows) node pool + role assignments. |
| `variables.tf`| All input variables (environment, region, vm sizes, node counts, ACR id, etc.).  |
| `outputs.tf`  | `kube_config`, `kube_host`, `client_certificate`, `client_key`, `cluster_ca_certificate`, `cluster_name`, `resource_group_name`. |

What it creates (`main.tf`):
- `azurerm_kubernetes_cluster.aks` (`main.tf:5`) - private cluster, `Standard` SKU, `SystemAssigned` identity, Azure CNI + Calico, standard load balancer, system node pool (`systempool`, autoscaled).
- `azurerm_kubernetes_cluster_node_pool.msapp` (`main.tf:70`) - **Windows** user node pool `mspool`, autoscaled.
- `azurerm_role_assignment.acr_pull` (`main.tf:85`) - grants the kubelet identity `AcrPull` on the ACR.
- `azurerm_role_assignment.aks_subnet_contributor` (`main.tf:91`) - grants the kubelet identity `Network Contributor` on the subnet.
- The `linuxapp` node pool is commented out (`main.tf:54`) - not currently used.

### `aks-terraform-prod/` - production AKS module

Same shape as `aks-terraform/` but adds:
- `data "azurerm_virtual_network" "existing_vnet"` (`main.tf:5`) - read the existing VNet (for the subnet/vnet role assignments).
- `azurerm_kubernetes_cluster_node_pool.linuxspot` (`main.tf:75`) - a **Linux Spot** user pool `spotpool` with `priority = "Spot"`, label `spot=true`, and taint `spot=true:NoSchedule`.
- `azurerm_kubernetes_cluster_node_pool.linuxspot2` (`main.tf:96`) - a second Linux Spot pool `spotpool2` (same configuration, separate min/max counts).
- `azurerm_role_assignment.aks_subnet_reader` (`main.tf:128`) - additional `Reader` on the VNet.
- Role assignments are scoped to `var.vnet_id` (vs. `subnet_id` in the non-prod module).

Extra variables vs. the dev/test module: `vnet_name`, `vnet_resource_group_name`, `vnet_id`, plus the `linuxspot`/`linuxspot2` size & min/max counts.

---

## Environment roots

All environment roots share the same layout:
- `main.tf` - `terraform { backend "azurerm" {...} }`, a `locals { tags }` block, `data` sources for the existing VNet/subnet, and a `module "aks-infra"` block sourcing the relevant module.
- `providers.tf` - `azurerm`, `azuread`, `kubernetes`, `kubectl`, `helm` providers + a `kubernetes_config_map "coredns_custom"` resource.
- `variables.tf` - the variables passed into the module.
- `terraform.tfvars` - the actual values for that environment.

### `prep-env/` - Prep environment

- Backend container: `testing` (`main.tf:5`).
- `environment = "DEV-TEST"` (`terraform.tfvars:12`).
- Sources `../aks-terraform` (`main.tf:51`).
- `providers.tf` configures `kubernetes`/`kubectl`/`helm` to authenticate via `az aks get-credentials --admin` (`exec` block) using the module outputs, and creates an empty `coredns-custom` ConfigMap in `kube-system` (`providers.tf:76`) - the actual data is later filled by the `HELM-coredns` chart.

### `test-env/` - Test environment

- Backend container: `testing` (`main.tf:5`).
- `environment = "DEV-TEST"` (`terraform.tfvars:12`).
- Sources `../aks-terraform`.
- Node sizes `Standard_B4as_v2`, K8s `1.30.9`.

### `QA-env/` - QA environment

- Backend container: `test-qa` (`main.tf:5`).
- `environment = "QA"` (`terraform.tfvars:12`).
- Sources `../aks-terraform`.
- K8s version `1.31.5` (newer than test).

### `prod-env/` - Production environment

- Backend container: `production` (`main.tf:5`).
- `environment = "Prod"` (`terraform.tfvars:12`).
- Sources `../aks-terraform-prod` (`main.tf:51`) - so it gets the extra Linux Spot pools.
- Passes the extra `vnet_id`/`vnet_name`/`vnet_resource_group_name` and `linuxspot*` variables.
- Production VM sizes: `Standard_D4as_v5` for system/linuxapp/msapp, `Standard_E8as_v5` for spot pools; spot pools can scale to 20 nodes.

---

## Per-environment values (terraform.tfvars)

| Variable                  | prep-env | test-env | QA-env | prod-env |
| ------------------------- | -------- | -------- | ------ | -------- |
| `environment`             | DEV-TEST | DEV-TEST | QA     | Prod     |
| `region`                  | westeurope | westeurope | westeurope | westeurope |
| `kubernetes_version`     | 1.30.9 | 1.30.9 | 1.31.5 | 1.30.9 |
| `system_vm_size`          | B4as_v2 | B4as_v2 | B4as_v2 | D4as_v5 |
| `linuxapp_vm_size`        | B4as_v2 | B4as_v2 | B4as_v2 | D4as_v5 |
| `msapp_vm_size`           | B4as_v2 | B4as_v2 | B4as_v2 | D4as_v5 |
| `linuxspot_vm_size`       | -       | -       | -       | E8as_v5 |
| `max_system_node_count`   | 3       | 3       | 3       | 3        |
| `max_linuxapp_node_count` | 10      | 10      | 10      | 3        |
| `max_msapp_node_count`    | 3       | 3       | 3       | 3        |
| `max_linuxspot_node_count`| -       | -       | -       | 20       |

State is stored in the same storage account (`tfstate`) under the `VirtualMachines` resource group, one container per environment (`testing`, `test-qa`, `production`).

---

## Usage

From an environment root:

```bash
terraform init -backend-config=...    # uses the azurerm backend in main.tf
terraform plan  -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

The `providers.tf` `kubernetes`/`kubectl`/`helm` providers use `az aks get-credentials --admin` (via `exec`) to authenticate against the cluster that was just created, so the same `terraform apply` can also create the empty `coredns-custom` ConfigMap. The actual CoreDNS host/domain overrides are then managed by the `HELM/HELM-coredns` chart.
