# WP Core Dispatch to GitHub

A lightweight WordPress MU-plugin that detects successful **WordPress core updates** and sends a [`repository_dispatch`](https://docs.github.com/en/rest/repos/repos#create-a-repository-dispatch-event) event to GitHub.

The dispatch can be consumed by a GitHub Actions workflow to automate follow-up tasks such as:

* Creating a new branch
* Updating a WordPress version in a Dockerfile
* Opening a Pull Request
* Triggering an image rebuild
* Running CI/CD validation after a WordPress upgrade

---

## Overview

The plugin listens for the WordPress:

```php
upgrader_process_complete
```

hook.

When the completed upgrade is identified as a **WordPress core update**, the plugin:

1. Reads the installed WordPress version.
2. Normalizes the version to `major.minor`.
3. Reads the site's unique `WP_SITE_KEY`.
4. Builds a metadata payload.
5. Sends a GitHub `repository_dispatch` request.
6. GitHub Actions receives the event and performs the required CI/CD automation.

---

## Architecture

```text
WordPress Core Update
        |
        v
upgrader_process_complete
        |
        v
Verify:
type = core
action = update
        |
        v
Read WordPress Version
        |
        v
Normalize Version
6.9.1 -> 6.9
        |
        v
Build Dispatch Payload
        |
        v
GitHub REST API
repository_dispatch
        |
        v
GitHub Actions Workflow
        |
        +--> Create branch
        +--> Update Dockerfile
        +--> Commit changes
        +--> Open PR
```

---

## Requirements

### WordPress

* WordPress with outbound HTTPS access
* MU-plugin support
* PHP with access to environment variables
* WordPress HTTP API (`wp_remote_post`)

### GitHub

A GitHub token capable of sending a repository dispatch event to the target repository.

The token should be stored in the WordPress environment as:

```text
GH_DISPATCH_TOKEN
```

Do **not** hardcode the token inside the plugin.

---

## Installation

Place the plugin inside the WordPress MU-plugin directory:

```text
wp-content/
└── mu-plugins/
    └── wp-core-dispatch.php
```

MU-plugins are automatically loaded by WordPress and do not need to be manually activated from the WordPress admin interface.

---

## Configuration

The plugin requires the following GitHub configuration:

```php
define('GH_OWNER', 'your-github-organization');
define('GH_REPO', 'your-repository');
define('GH_TOKEN', getenv('GH_DISPATCH_TOKEN'));
define('GH_EVENT_TYPE', 'wp_core_updated');
```

---

## Environment Variables

### `GH_DISPATCH_TOKEN`

GitHub token used to authenticate the API request.

Example:

```bash
GH_DISPATCH_TOKEN=github_pat_xxxxxxxxxxxxxxxxx
```

---

### `WP_SITE_KEY`

Unique identifier for the WordPress instance.

Example:

```bash
WP_SITE_KEY=customer-production
```

The plugin first checks:

```php
getenv('WP_SITE_KEY')
```

and then falls back to:

```php
WP_SITE_KEY
```

if defined as a PHP constant.

If neither exists, the site key becomes:

```text
unknown
```

and the dispatch is skipped.

---

### `ENVIRONMENT`

Identifies the WordPress environment.

Example:

```bash
ENVIRONMENT=production
```

Typical values could be:

```text
development
staging
production
```

If the variable is missing, the payload contains:

```text
unknown
```

---

## GitHub Event

The plugin sends the following event type:

```text
wp_core_updated
```

GitHub Actions can listen for it using:

```yaml
on:
  repository_dispatch:
    types:
      - wp_core_updated
```

---

## Dispatch Payload

The plugin sends a payload similar to:

```json
{
  "event_type": "wp_core_updated",
  "client_payload": {
    "site_key": "customer-production",
    "wp_version": "6.9",
    "site_url": "https://example.com",
    "environment": "production",
    "timestamp": "2026-09-23T06:00:00+00:00",
    "source": "upgrader_process_complete"
  }
}
```

### Payload fields

| Field         | Description                                     |
| ------------- | ----------------------------------------------- |
| `site_key`    | Unique identifier of the WordPress installation |
| `wp_version`  | WordPress version normalized to `major.minor`   |
| `site_url`    | WordPress site URL                              |
| `environment` | Deployment environment                          |
| `timestamp`   | UTC timestamp when the event was generated      |
| `source`      | WordPress hook responsible for the event        |

---

## Version Normalization

The plugin intentionally removes the patch number.

Examples:

| Installed version | Sent to GitHub |
| ----------------- | -------------- |
| `6.3`             | `6.3`          |
| `6.3.7`           | `6.3`          |
| `6.8.2`           | `6.8`          |
| `6.9-beta1`       | `6.9`          |

This is useful when the Docker image or Dockerfile tracks only WordPress `major.minor` releases.

---

## Example GitHub Actions Workflow

A basic receiver workflow could look like:

```yaml
name: WordPress Core Update

on:
  repository_dispatch:
    types:
      - wp_core_updated

jobs:
  handle-wordpress-update:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Show received payload
        run: |
          echo "Site: ${{ github.event.client_payload.site_key }}"
          echo "Environment: ${{ github.event.client_payload.environment }}"
          echo "WordPress version: ${{ github.event.client_payload.wp_version }}"
          echo "URL: ${{ github.event.client_payload.site_url }}"

      - name: Create branch name
        run: |
          echo "BRANCH_NAME=wp-update/${{ github.event.client_payload.site_key }}-${{ github.event.client_payload.wp_version }}" >> "$GITHUB_ENV"

      - name: Create branch
        run: |
          git checkout -b "$BRANCH_NAME"
```

The actual receiver implementation lives in this repo in `wp-core-bump-branch.yml` and is documented below.

---

## Receiver Workflow - `wp-core-bump-branch.yml`

The companion GitHub Actions workflow that consumes the `repository_dispatch` event sent by the MU-plugin. It updates the WordPress base image in the relevant per-site Dockerfile on the correct branch of the ort-monorepo.

### Trigger

```yaml
on:
  repository_dispatch:
    types: [wp_core_updated]
```

Only responds to dispatch events with `event_type = wp_core_updated` (the type sent by the plugin). Runs on the self-hosted runner `ubuntu-custom`.

### Concurrency

```yaml
concurrency:
  group: wp-bump-${{ github.workflow }}-${{ github.event.client_payload.environment }}-${{ github.event.client_payload.site_key }}
  cancel-in-progress: false
```

One in-flight bump per `environment + site_key` combination; queued bumps are not cancelled, so a rapid succession of WordPress updates will all be applied in order.

### Permissions

`contents: write` is required because the workflow commits and pushes directly to the target branch.

### Job `bump-direct` - steps

1. **Validate payload + decide target branch** (`wp-core-bump-branch.yml:19`)
   - Reads `site_key`, `wp_version`, `environment` from `client_payload`.
   - Validates `site_key` matches `^[a-z0-9-]+$` and `wp_version` matches `^[0-9]+(\.[0-9]+){1,3}$` - fails fast on malformed input.
   - Maps `environment` to a target branch:
     - `testing` -> `testing`
     - `production` -> `main`
     - anything else -> fail.
   - Computes `DOCKERFILE = wp-<site_key>/Dockerfile`.
   - Exposes all of the above as step outputs for later steps.

2. **Checkout ort-monorepo target branch** (`:56`)
   - Uses `actions/checkout@v7` with `ref: <target_branch>`, `fetch-depth: 0` (full history for the rebase later), and `token: ${{ secrets.MONOREPO_TOKEN }}` (a PAT that can push to the monorepo).

3. **Update Dockerfile and push to target branch** (`:64`)
   - Fails if the Dockerfile does not exist.
   - Checks out the target branch.
   - Prints the current core `FROM` line for visibility.
   - **Idempotency guard**: if the core `FROM` line already contains the requested `${WPV}`, exits `0` with "No change needed".
   - **Targeted replacement**: uses a strict `sed -E` regex to replace ONLY the line matching
     ```
     FROM wordpress:<old>-phpX.Y-fpm AS core
     ```
     with
     ```
     FROM wordpress:<WPV>-phpX.Y-fpm AS core
     ```
     The regex is anchored (`^...$`) and case-insensitive, and only touches the `core` stage - the `publish` stage (`FROM wordpress:phpX.Y-fpm AS publish`) is left untouched.
   - **Verification**: after the `sed`, asserts the new core line contains `${WPV}` AND that the versionless `publish` line is still intact. If either check fails, the step prints all `FROM wordpress:` lines for debugging and exits non-zero.
   - **Commit & push**: configures the `wp-core-bot` git identity, commits with message `chore(<site>): bump WP base image to <WPV> (<env>)`, runs `git pull --rebase origin <branch>` to fold in any concurrent changes, and pushes `HEAD` to the target branch.

### Net effect

When WordPress core is updated on a site (e.g. to `6.9`), the MU-plugin dispatches to GitHub, and this workflow rewrites only the `core` stage `FROM` line in `wp-<site>/Dockerfile` on the matching branch (`testing` or `main`), leaving every other stage and every other site's Dockerfile untouched. The updated Dockerfile then flows through the normal image build pipeline to produce a new WordPress container image at the new core version.

A complete implementation could then:

```text
Receive dispatch
      |
      v
Determine site / Dockerfile
      |
      v
Create update branch
      |
      v
Change WordPress version
      |
      v
Commit
      |
      v
Push branch
      |
      v
Create Pull Request
```

---

## GitHub API Request

The plugin sends a POST request to:

```text
https://api.github.com/repos/<OWNER>/<REPO>/dispatches
```

using:

```http
Authorization: Bearer <GH_DISPATCH_TOKEN>
Accept: application/vnd.github+json
Content-Type: application/json
```

The request body contains:

```json
{
  "event_type": "wp_core_updated",
  "client_payload": {}
}
```

---

## Trigger Conditions

The dispatch runs only when the WordPress upgrade event reports:

```php
$hook_extra['type'] === 'core'
```

and, when present:

```php
$hook_extra['action'] === 'update'
```

Plugin and theme updates are therefore ignored.

---

## Logging

The plugin writes diagnostic information using:

```php
error_log()
```

When the MU-plugin loads:

```text
[WP Core Dispatch] MU-plugin loaded
```

When an update is detected:

```text
[WP Core Dispatch] Version raw=6.9.1 normalized=6.9
```

Before contacting GitHub:

```text
[WP Core Dispatch] Sending repository_dispatch: site_key=customer-production wp_version=6.9 env=production
```

GitHub's response is also logged:

```text
[WP Core Dispatch] GitHub response code=204 body=
```

A successful GitHub repository dispatch normally returns:

```text
204 No Content
```

---

## Error Handling

### Missing site key

If `WP_SITE_KEY` cannot be resolved:

```text
[WP Core Dispatch] WP_SITE_KEY is unknown - skipping dispatch
```

No GitHub request is sent.

---

### Missing GitHub token

If `GH_DISPATCH_TOKEN` is unavailable:

```text
[WP Core Dispatch] GH_DISPATCH_TOKEN is missing - skipping dispatch
```

---

### Invalid WordPress version

If the plugin cannot determine a valid `major.minor` version:

```text
[WP Core Dispatch] Could not normalize version: ...
```

---

### GitHub API failure

WordPress HTTP API errors are logged as:

```text
[WP Core Dispatch] Failed: <error>
```

HTTP response codes returned by GitHub are also logged for debugging.

---

## Security

The GitHub token should **never** be committed to the repository or stored directly in the plugin.

Use an environment variable:

```bash
GH_DISPATCH_TOKEN=...
```

and expose it to PHP through the runtime environment.

The GitHub token should also follow the principle of least privilege and only receive the permissions required to dispatch events to the target repository.

---

## Example Docker Configuration

For a containerized WordPress deployment, the required environment variables could be injected through the deployment configuration.

Example:

```yaml
environment:
  WP_SITE_KEY: customer-production
  ENVIRONMENT: production
  GH_DISPATCH_TOKEN: ${GH_DISPATCH_TOKEN}
```

The actual token should preferably come from a secret-management solution rather than being stored directly in the Compose file.

---

## Expected Workflow

An example end-to-end lifecycle:

```text
WordPress 6.8.x
      |
      | WordPress automatic/manual core update
      v
WordPress 6.9.x
      |
      | MU-plugin detects update
      v
repository_dispatch
      |
      | wp_version = 6.9
      | site_key = customer-production
      v
GitHub Actions
      |
      v
Branch:
wp-update/customer-production-6.9
      |
      v
Dockerfile updated
      |
      v
Pull Request
      |
      v
Review / Merge / Deploy
```

---

## Purpose

This plugin is intended to bridge the gap between **WordPress runtime updates** and the **infrastructure-as-code repository** responsible for building the WordPress deployment in a Kubernetes environment.

Instead of allowing the running WordPress instance and the Docker configuration to drift apart, a successful core update can automatically notify the CI/CD repository that its declared WordPress version should be updated.

---

## License

Internal / project-specific use unless otherwise specified.

