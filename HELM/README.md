# HELM Charts

This folder contains the Helm charts used to deploy the CET application stack and custom DNS configuration onto Azure Kubernetes Service (AKS) clusters.

## Folder structure

```
HELM/
├── HELM-app/        # Application chart - deploys all CET microservices
└── HELM-coredns/    # CoreDNS custom-config chart - DNS overrides per environment
```

---

## HELM-app

A generic, data-driven Helm chart (`apiVersion: v2`, chart name `app`) that deploys **all CET microservices** from a single chart. Rather than one template per service, it iterates over a `services` map in `values.yaml` and generates the Kubernetes objects for every enabled service.

Current chart version is `14.70.0-202510301045` (`Chart.yaml:16`).

### Files

| Path                         | Purpose                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `Chart.yaml`                 | Chart metadata, `version` and `appVersion` (driven by CI bumps).        |
| `values.yaml`                | Default values - all services disabled, sample service definitions.   |
| `templates/_helpers.tpl`     | The heart of the chart - four reusable template blocks (see below).    |
| `templates/main.yaml`        | Entry point that includes the four helper blocks in order.             |
| `.helmignore`                | Files excluded from the packaged chart.                                |
| `ENV/Testing/`               | Testing environment values + `Config.yaml` (cluster info) + version.   |
| `ENV/Preprod/`               | Preprod environment values.                                             |
| `ENV/Production/`            | Production environment values.                                          |

### How it works

`templates/main.yaml` includes four blocks defined in `templates/_helpers.tpl`:

1. **`createDeployments`** (`_helpers.tpl:1`) - iterates `values.services` and, for each service enabled under `values.serviceEnable`, renders a `Deployment` with:
   - RollingUpdate strategy, replicas (per-service or `global.spec.replicas`).
   - `nodeSelector`, container ports (special-casing `xapifunction` -> 8080), `image: <acrUrl>/<name>:<imageTag>`.
   - Optional ramdisk `emptyDir` volume, optional PVC mount.
   - Resources (limits/requests) per-service or from `global.resources`.
   - Environment variables from `envVars`, `envVarsFromGlobal`, and ramdisk-specific vars.
   - Liveness/readiness probes (HTTP or TCP socket).
   - Optional `hostAliases`.
2. **`createServices`** (`_helpers.tpl:189`) - renders a `LoadBalancer` `Service` for each enabled service (`<name>-service`).
3. **`createHPA`** (`_helpers.tpl:259`) - renders a `HorizontalPodAutoscaler` (CPU + memory, optional external Service Bus metric) per enabled service.
4. **`createAPIServices`** (`_helpers.tpl:237`) - registers the `v1beta1.external.metrics.k8s.io` APIService pointing at `servicebusmetrics-service` (only when `servicebusmetrics` is enabled, used by the external-metrics HPA).

### Values shape

```yaml
global:
  acrUrl: <acr>.azurecr.io      # container registry used in image references
  ports: { containerPort: ... }
  resources: { limitscpu, limitsmemory, requestscpu, requestsmemory }
  livenessProbe / readinessProbe: { path, initialDelaySeconds, ... }
  nodeSelector: { ... }
  autoscaling: { minReplicas, maxReplicas, metrics: { cpuaverageUtilization, memoryaverageValue } }

serviceEnable:                  # toggle each service on/off per environment
  <serviceName>: true|false

services:                       # per-service definition
  <serviceName>:
    name: <name>                # base name for objects + image tag
    imageTag: vX.Y.Z            # container tag to deploy
    imageName: <repo>           # source repository (informational)
    # optional: ports, resources, nodeSelector, envVars, envVarsFromGlobal,
    #            autoscaling, ramdisk, volumeCalim, hostAliases, livenessProbe,
    #            readinessProbe, isTcpSocket, includeExternalMetric
```

### Per-environment files (`ENV/<env>/`)

- `Config.yaml` - `cluster_name`, `cluster_resource_group`, `helm_chart_name`, `helm_values_file`, `azure_subscription_id`. Consumed by the Jenkins deploy pipeline (`Jenkins/jenkinsfile_unitedDeploy`).
- `values.yaml` - the values file actually deployed (a copy of `values-testing.yaml` / `values-prod.yaml` updated by the update pipeline).
- `values-testing.yaml` / `values-prod.yaml` - baseline values for that environment.
- `currentVersion.txt` - the chart version currently deployed to that environment (written by the deploy pipeline).

---

## HELM-coredns

A small Helm chart (`apiVersion: v1`, chart name `coredns-custom`, version `2.7.0`) that deploys a **custom CoreDNS ConfigMap** (`coredns-custom` in the `kube-system` namespace) used by AKS to add DNS overrides per environment.

### Files

| Path                          | Purpose                                                          |
| ----------------------------- | ---------------------------------------------------------------- |
| `Chart.yaml`                  | Chart metadata.                                                  |
| `templates/_helpers.tpl`      | Standard name/fullname helpers (truncated to 63 chars).          |
| `templates/configmap.yaml`    | Renders the `coredns-custom` ConfigMap from `values`.           |
| `ENV/values-testing.yaml`     | Testing DNS overrides (per-service hostnames + hosts).         |
| `ENV/values-prep.yaml`        | Prep/preprod DNS overrides (bare hostnames + IP placeholders).   |
| `ENV/values-prod.yaml`        | Production DNS overrides (per-service hostnames + DB/Redis/etc.). |

### How it works

`templates/configmap.yaml` produces two ConfigMap keys:

- **`test.override`** - a `hosts {}` block mapping hostnames from `values.hosts` to IPs, with `fallthrough`.
- **`test.server`** - per-domain server blocks from `values.domains`, each rewriting the public hostname to the in-cluster `<key>-service.default.svc.cluster.local` and forwarding the rest to `/etc/resolv.conf`.

So for example in production (`ENV/values-prod.yaml`), each domain entry rewrites the configured public hostname to `<serviceKey>-service.default.svc.cluster.local`, allowing in-cluster services to call each other using their public hostnames.

### Values shape

```yaml
domains:
  <serviceKey>: "<public-hostname>"   # rewrite <public-hostname> -> <serviceKey>-service
hosts:
  <hostname>: <ip>                    # static /etc/hosts-style override
```

---

## Usage

Charts are packaged and pushed to ACR by the `Jenkins/jenkinsfile_unitedUpdate` pipeline, and deployed by `Jenkins/jenkinsfile_unitedDeploy`. See the `Jenkins/README.md` for the full CI/CD flow.
