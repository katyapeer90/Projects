# Jenkins Pipelines

This folder contains the Jenkins pipeline definitions (Jenkinsfiles / Groovy) that build, publish, version and deploy the  microservices and Helm charts.

## Files

```
Jenkins/
├── servicesDeploy         # Build + publish Docker images and deploy unmanaged apps
├── jenkinsfile_unitedDeploy # Deploy the united Helm chart to an AKS environment
└── jenkinsfile_unitedUpdate # Bump a service image tag + create/push a new chart version
```

All three pipelines share a `jenkins-shared-library` (`@Library('jenkins-shared-library')_`) and use the same Azure DevOps git credential ID `1d641054-6340-40a3-932d-8d01029eafaf`.

---

## 1. `servicesDeploy` - Build & Publish service images

The main build pipeline for the  microservices. Triggered by Azure DevOps PR webhooks (`PAYLOAD`) or run manually with parameters.

### Parameters (`servicesDeploy:19-98`)

- **Build section**
  - `PushBRANCH` - branch to build (empty when triggered by webhook).
  - `DISABLE_NOTIFICATION` - suppress failure email.
  - `versionType` - `major`/`minor`/`patch` bump (auto-detected if empty).
  - `servicename` - single-select list of ~60  services (Groovy script).
  - `infinityAppSelection` - `frontend`/`backend` (only for `infinity`).
- **Deploy section**
  - `Deploy` - `Yes`/`No`. `No` = build; `Yes` = deploy an existing image to Dev-IL.
  - `pushService` - the ACR repository to deploy.
  - `pushVersion` - cascading list of tags fetched live from ACR via `az acr repository show-tags`.

### Stages (build path, `Deploy == 'No'`)

1. **Prep** (`servicesDeploy:115`) - parses the Azure DevOps webhook payload to resolve `PushBRANCH`, `nairobiservicename`, `developerEmail`, `status` (`active`/`completed`), `pullRequestId`. Special-cases `_*`/`-develop`/`-release` branches to the `learning` service.
2. **Checkout** (`servicesDeploy:174`) - calls `checkoutservice()` which maps the chosen service to its git repo and checks out the branch. Then applies per-service Dockerfile/.env tweaks (e.g. `StudentsWebApp`, `LearningTogether*`, `collaboration`, `HendrXPoc`, `learning-api`). Computes `NEW_COMMIT_SHA`, `FULL_COMMIT_SHA`, and sets `sonarScan=true` for the services that should be SonarQube-scanned.
3. **Orca Security Scan** (`servicesDeploy:261`) - runs Orca CLI IaC, filesystem and secrets scans against the workspace (skipped for `Asset-AI`).
4. **SonarQube** (`servicesDeploy:282`) - triggers the `sonarQubeScan` job for services flagged above; failures are non-blocking.
5. **Build and Publish Docker** (`servicesDeploy:300`) - logs into Azure, computes the docker image name via `kubname()`, reads the latest tag from ACR (or starts at `0.0.0`), bumps it via `globalversionBump()`, writes `version.json`, then calls `checkacrtobuild()` which builds, tags and pushes `ACR/<dockername>:v<version>`. Per-service build args handle `hendrxpoc`/`collaboration`/`learning*` and `infinity` (front/back split). After pushing, `runLTjobs()` triggers companion builds (e.g. `LearningTogetherAS`/`AC` after `LearningTogether`, `learning-collaboration`/`learning-api` after `learning`).
6. **Deploy unmanaged apps** (`servicesDeploy:363`) - for `LearningTogether*` and `WhatsAppService`, checks out the `JnkinsfileNairobi` repo and applies a `deployment.yaml`/`deploymentprod.yaml` to the DEV or prod AKS cluster with `sed` substitutions.

### Stages (deploy path, `Deploy == 'Yes'`)

7. **Deploy to Dev-IL** (`servicesDeploy:404`) - checks out the `jenkinsHelm` repo, logs into Azure, gets credentials for `-K8s-DEV-TEST`, then picks the right deployment YAML per service (`apigateway`, `hendrxpoc`, `collaboration`, `learning-api`, `identitymanagementapi`, `moodle`, `learning`, `learning-collaboration`, `itestai`, `infinity`, `infinityapi` or the generic `deployment.yaml`) and `kubectl apply`s it after substituting the image name/version and environment-specific endpoints.

### Post actions (`servicesDeploy:524`)

- Sets a build description via `setBuildDescription` / `setBuildDescriptionDeploy`.
- On success with an `active` PR: approves the Azure DevOps PR and updates its description with the image/build URL.
- On failure: rejects the PR and sends an email to the developer (unless `DISABLE_NOTIFICATION`).

### Key helper functions

- `kubname()` (`servicesDeploy:584`) - maps a service name to its ACR repository name (e.g. `NairobiWebApp` -> `nairobisite`, `.XApi.Function` -> `xapifunction`). Also triggers the chained `infinity` backend build when the frontend is built.
- `runLTjobs()` (`servicesDeploy:693`) - triggers dependent builds (LearningTogether family, ApiGateway -> APIGW, HendrXPoc -> collaboration, learning -> learning-collaboration + learning-api).
- `checkacrtobuild()` (`servicesDeploy:716`) - builds, tags and pushes the Docker image; if the tag already exists it rebuilds anyway (ensuring the bump is always applied).
- `checkoutservice()` (`servicesDeploy:877`) - maps each service name to its git URL and checks out the requested branch.
- `globalversionBump()` - splits a `major.minor.patch` string and bumps the requested component.

---

## 2. `jenkinsfile_unitedDeploy` - Deploy the united Helm chart

Deploys the `app` Helm chart (from `HELM/HELM-app`) to a chosen AKS environment. Runs on the `Ansible-IT` agent.

### Parameters (`jenkinsfile_unitedDeploy:6-17`)

- `ENV` - `Testing` / `PreProd` / `Production`.
- `chartVersion` - Helm chart version to deploy. Leave empty to redeploy the currently-deployed version.

### Stages

1. **Checkout** (`jenkinsfile_unitedDeploy:34`) - checks out the `-app` repo (which contains the chart + `ENV/`).
2. **Prepare values.yaml file for environment** (`:99`) - selects `ENV/<env>/` path and the matching `values-*.yaml` based on `ENV`.
3. **Extract parameters from values.yaml** (`:117`) - reads `ENV/<env>/Config.yaml` to get `cluster_name`, `cluster_resource_group`, `chart_name`.
4. **Deploy helm chart** (`:136`) - logs into Azure, gets AKS credentials, finds the currently deployed chart version via `helm ls`, defaults `chartVersion` to the current version if empty, validates `x.x.x` format for Production, runs `helm diff upgrade` for a preview, prompts for manual confirmation (`input`), then runs `helm upgrade -i <chart> oci://ACR/<chart> --version <ver> -f <values> --force`.
5. **Update version in repo** (`:205`) - writes the deployed version back to `ENV/<env>/currentVersion.txt` and pushes to the `-app` repo (only commits if there is a diff).

### Post (`:267`)

- Always sets the build description (`ENV`, `chartVersion`).
- Success/failure sends an `emailext` notification with the attached log.

---

## 3. `jenkinsfile_unitedUpdate` - Bump image tag + release new chart version

Updates a service's `imageTag` in the environment's `values.yaml` and optionally cuts a new Helm chart release. Runs on the `Ansible-IT` agent.

### Parameters (`jenkinsfile_unitedUpdate:6-77`)

- `SERVICE_NAME` - single-select list of all  services (sorted).
- `NEW_IMAGE_TAG` - cascading list of tags fetched live from ACR for the selected service.
- `ENV` - `Testing` / `Preprod` / `Production`.
- `releaseVersion` - cascading `minor`/`major`/`patch` (only for Production).
- `releaseDescription` - free text included in the commit/tag message.
- `Create_Version` - if checked, create and push a new chart version.

### Stages

1. **Checkout** (`jenkinsfile_unitedUpdate:94`) - checks out the `app` repo.
2. **Update Image Tag** (`:108`) - copies `ENV/<env>/values.yaml` to the workspace, regex-replaces the `imageTag` for the selected service, and writes it back to both the workspace file and `ENV/<env>/values.yaml`.
3. **Update Chart.yaml** (`:138`, only when `Create_Version`) - per environment:
   - **Testing / Preprod** - appends a timestamp `-YYYYMMDDHHMM` (preprod also adds `-preprod`) to the existing semver in `version`/`appVersion`, then commits and pushes to `main`.
   - **Production** - reads the last git tag (`git describe --tags --abbrev=0`), bumps it with `globalversionBump()` using the selected `releaseVersion`, updates `Chart.yaml`, commits, pushes, **and creates+pushes an annotated git tag** for the new version.
4. **upload file to remote** (`:285`, when `!Create_Version`) - just commits and pushes the imageTag change without a chart version bump.
5. **Push chart to ACR** (`:319`, when `Create_Version`) - moves `ENV/<env>/values.yaml` to the workspace, removes the `ENV/` folder, runs `helm package app`, logs into Azure, and `helm push app-<chartVersion>.tgz oci://ACR`.
6. **Bumping the version for next release** (`:349`, Production + non-patch) - re-checks out the repo, bumps the last git tag by `minor`, writes it into `Chart.yaml` as the in-development version, commits and pushes (so the next release has a `-dev`-style starting point).

### Post (`:408`)

- Sets a build description (with or without chart version).
- Success/failure sends an `emailext` notification referencing the service and new tag.

---

## End-to-end flow

```text
Developer opens PR  ──> servicesDeploy (build path)
   ├─ Orca + SonarQube scans
   ├─ docker build & push ACR/<service>:v<bumped>
   └─ (PR auto-approved on success / rejected on failure)

Dev-IL deploy       ──> servicesDeploy (Deploy=Yes)
   └─ kubectl apply <service>.yaml to -K8s-DEV-TEST

Release new chart   ──> jenkinsfile_unitedUpdate (Create_Version)
   ├─ Update imageTag in ENV/<env>/values.yaml
   ├─ Bump Chart.yaml version + git tag (Production)
   ├─ helm package + helm push to ACR
   └─ (Production non-patch) bump next-release dev version

Deploy chart        ──> jenkinsfile_unitedDeploy
   ├─ helm diff upgrade  (manual confirmation)
   ├─ helm upgrade -i oci://ACR/app --version <ver> -f ENV/<env>/values.yaml
   └─ write currentVersion.txt back to repo
```
