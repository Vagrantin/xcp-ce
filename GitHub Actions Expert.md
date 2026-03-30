# GitHub Actions Expert

Use this skill whenever the user asks anything about GitHub Actions — writing or debugging
workflows, CI/CD pipelines, triggers/events, runners (GitHub-hosted or self-hosted), secrets
and variables, reusable workflows, composite actions, matrix builds, caching, artifacts,
environments and deployments, OIDC authentication, permissions, or any `.github/workflows`
YAML. Trigger even for related terms like "Actions pipeline", "workflow file", "gh actions",
"on: push", "runs-on", "workflow_dispatch", or "GitHub CI".

---

## 1. Core Reference URLs

| Topic | URL |
|---|---|
| GitHub Actions home | https://docs.github.com/en/actions |
| Understanding Actions | https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions |
| Workflow syntax (full ref) | https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions |
| Events that trigger workflows | https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows |
| Contexts reference | https://docs.github.com/en/actions/learn-github-actions/contexts |
| Expressions | https://docs.github.com/en/actions/learn-github-actions/expressions |
| Secrets | https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions |
| Variables | https://docs.github.com/en/actions/learn-github-actions/variables |
| Reusable workflows | https://docs.github.com/en/actions/using-workflows/reusing-workflows |
| Custom actions | https://docs.github.com/en/actions/creating-actions/about-custom-actions |
| GitHub-hosted runners | https://docs.github.com/en/actions/using-github-hosted-runners |
| Self-hosted runners | https://docs.github.com/en/actions/hosting-your-own-runners |
| Caching dependencies | https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows |
| Artifacts | https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts |
| Environments & deployments | https://docs.github.com/en/actions/deployment/targeting-different-environments |
| OIDC (keyless auth) | https://docs.github.com/en/actions/deployment/security-hardening/about-security-hardening-with-openid-connect |
| GitHub Marketplace (Actions) | https://github.com/marketplace?type=actions |
| Starter workflows | https://github.com/actions/starter-workflows |

---

## 2. Core Concepts

### Architecture overview

```
Repository (.github/workflows/*.yml)
        │
        ▼  triggered by Event (push, PR, schedule, etc.)
   Workflow
        │
        ├── Job A ──► Runner (ubuntu-latest / windows / macos / self-hosted)
        │     ├── Step 1: uses: actions/checkout@v4
        │     ├── Step 2: run: npm install
        │     └── Step 3: run: npm test
        │
        └── Job B (runs after Job A via needs:)
              └── Step 1: Deploy
```

### Key building blocks

| Concept | Description |
|---|---|
| **Workflow** | YAML file in `.github/workflows/`. One repo can have many. |
| **Event** | What triggers the workflow (`push`, `pull_request`, `schedule`, `workflow_dispatch`, etc.) |
| **Job** | A set of steps running on the same runner. Jobs run in parallel by default. |
| **Step** | Individual task: either `run:` (shell script) or `uses:` (an Action). |
| **Action** | A reusable unit of work — from Marketplace, a local path, or a Docker image. |
| **Runner** | The VM that executes a job. GitHub-hosted or self-hosted. |
| **Context** | Objects exposing runtime info: `github`, `env`, `secrets`, `vars`, `runner`, `job`, `steps`, `needs`, `inputs`. |
| **Expression** | `${{ }}` syntax to evaluate contexts and functions in YAML values. |

---

## 3. Workflow YAML Anatomy

```yaml
name: CI Pipeline                        # Display name (optional)
run-name: ${{ github.actor }} triggered  # Dynamic run name (optional)

on:                                      # TRIGGER(S)
  push:
    branches: [main, 'release/**']
    paths-ignore: ['**.md']
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 1'                  # Every Monday at 02:00 UTC
  workflow_dispatch:                     # Manual trigger with optional inputs
    inputs:
      environment:
        type: choice
        options: [staging, production]
        default: staging

env:                                     # Workflow-level env vars
  NODE_VERSION: '20'

jobs:
  build:
    name: Build & Test
    runs-on: ubuntu-latest               # Runner label
    permissions:                         # Least-privilege — always set
      contents: read
    
    strategy:                            # Matrix: run job multiple times
      matrix:
        node: [18, 20, 22]
      fail-fast: false                   # Don't cancel all if one fails

    steps:
      - name: Checkout
        uses: actions/checkout@v4        # Always pin to SHA or major tag

      - name: Setup Node ${{ matrix.node }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'                   # Built-in caching via setup actions

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}   # Inject secret as env var

      - name: Upload coverage
        if: always()                     # Run even if previous step fails
        uses: actions/upload-artifact@v4
        with:
          name: coverage-node-${{ matrix.node }}
          path: coverage/
          retention-days: 7

  deploy:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build                         # Wait for 'build' job to succeed
    if: github.ref == 'refs/heads/main'  # Only on main branch
    environment: staging                 # Requires environment approval if configured
    
    steps:
      - uses: actions/checkout@v4
      - name: Deploy
        run: ./scripts/deploy.sh
```

---

## 4. Events (Triggers) Reference

### Most common triggers

```yaml
on:
  push:                         # Any push
    branches: [main]
    tags: ['v*']
    paths: ['src/**']

  pull_request:                 # PR opened/synchronized/reopened
    types: [opened, synchronize, reopened]

  pull_request_target:          # PR from fork — has write perms, use carefully

  workflow_dispatch:            # Manual button in GitHub UI

  workflow_call:                # Called by another workflow (reusable)

  schedule:
    - cron: '*/15 * * * *'      # Every 15 minutes

  release:
    types: [published]

  issue_comment:
    types: [created]

  repository_dispatch:          # External webhook trigger via API

  merge_group:                  # Merge queue trigger
```

### Filtering tips
- `branches-ignore:` and `paths-ignore:` are the inverse filters.
- `paths:` and `branches:` on `push` and `pull_request` are AND'd together.
- Tag patterns use glob: `'v[0-9]+.[0-9]+.[0-9]+'`

---

## 5. Contexts Quick Reference

Access via `${{ context.property }}` in YAML:

| Context | Key Properties |
|---|---|
| `github` | `.event_name`, `.ref`, `.sha`, `.actor`, `.repository`, `.workflow`, `.run_id`, `.run_number` |
| `env` | Custom env vars set in workflow/job/step |
| `vars` | Repository/org configuration variables (non-secret) |
| `secrets` | `secrets.GITHUB_TOKEN`, `secrets.MY_SECRET` |
| `runner` | `.os`, `.arch`, `.temp`, `.tool_cache` |
| `job` | `.status` |
| `steps` | `steps.<step_id>.outputs.<name>`, `steps.<step_id>.outcome` |
| `needs` | `needs.<job_id>.outputs.<name>`, `needs.<job_id>.result` |
| `inputs` | Inputs from `workflow_dispatch` or `workflow_call` |
| `matrix` | `matrix.<variable>` in matrix jobs |

### Passing data between steps and jobs

```yaml
# Between steps (same job) — via $GITHUB_OUTPUT
- name: Set output
  id: my_step
  run: echo "version=1.2.3" >> $GITHUB_OUTPUT

- name: Use output
  run: echo "Version is ${{ steps.my_step.outputs.version }}"

# Between jobs — via job outputs
jobs:
  job1:
    outputs:
      tag: ${{ steps.get_tag.outputs.tag }}
    steps:
      - id: get_tag
        run: echo "tag=v1.0" >> $GITHUB_OUTPUT

  job2:
    needs: job1
    steps:
      - run: echo "${{ needs.job1.outputs.tag }}"
```

---

## 6. Secrets and Variables

### Secrets (encrypted, for sensitive values)
```yaml
# Inject as env var (recommended)
env:
  MY_TOKEN: ${{ secrets.MY_TOKEN }}

# Pass to action input
- uses: some/action@v1
  with:
    token: ${{ secrets.MY_TOKEN }}
```

**Important rules:**
- Secrets are **redacted from logs** automatically.
- `GITHUB_TOKEN` is auto-provided per run — use it for GitHub API calls.
- Secrets from forks are **not available** in `pull_request` triggered workflows (use `pull_request_target` carefully).
- Secrets cannot be used in `if:` conditionals directly — set as env var first.

### Variables (non-secret config)
```yaml
# Access via vars context
run: echo "Environment is ${{ vars.ENVIRONMENT }}"
```
Set at repo/org level: Settings → Secrets and variables → Actions → Variables tab.

---

## 7. Runners

### GitHub-hosted runner labels
| Label | OS | Notes |
|---|---|---|
| `ubuntu-latest` / `ubuntu-24.04` | Ubuntu 24.04 | Default, fastest startup |
| `ubuntu-22.04` | Ubuntu 22.04 | LTS, most compatible |
| `windows-latest` / `windows-2025` | Windows Server 2025 | |
| `macos-latest` / `macos-15` | macOS 15 | Slowest, needed for iOS/macOS builds |
| `macos-13` | macOS 13 (Intel) | Last Intel macOS runner |

### Self-hosted runners
```yaml
runs-on: [self-hosted, linux, x64, my-label]
```
- Register via: repo/org Settings → Actions → Runners → New self-hosted runner.
- Runs the `actions-runner` agent that polls GitHub.
- Use runner groups (GitHub Enterprise / org level) for access control.
- Self-hosted runners persist state between runs — clean up carefully.

---

## 8. Caching

```yaml
# Option 1: setup actions handle caching automatically
- uses: actions/setup-node@v4
  with:
    cache: 'npm'    # or 'yarn', 'pnpm'

# Option 2: manual cache
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```
- Cache is keyed by `key:` — exact match restores. `restore-keys:` are fallback prefixes.
- Cache scoped to branch; `main`/default branch cache is readable by all branches.
- Max cache size: 10 GB per repository.

---

## 9. Artifacts

```yaml
# Upload
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: dist/
    retention-days: 30       # Default: 90 days

# Download (same or different job)
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./downloaded/
```
Use artifacts to pass **files** between jobs; use job outputs for **strings**.

---

## 10. Reusable Workflows

### Defining a reusable workflow
```yaml
# .github/workflows/deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      DEPLOY_KEY:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh ${{ inputs.environment }}
        env:
          KEY: ${{ secrets.DEPLOY_KEY }}
```

### Calling a reusable workflow
```yaml
jobs:
  call-deploy:
    uses: my-org/infra/.github/workflows/deploy.yml@main
    with:
      environment: production
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
    # OR: secrets: inherit   (passes all secrets automatically)
```

---

## 11. Custom Actions

### Three types

| Type | Speed | Platform | Use When |
|---|---|---|---|
| **JavaScript** | Fast | Any runner | General purpose, most common |
| **Docker container** | Slower | Linux only | Specific environment needed |
| **Composite** | Fast | Any runner | Bundling multiple run steps |

### Composite action example (`action.yml`)
```yaml
name: 'Setup and Build'
description: 'Installs deps and builds the project'
inputs:
  node-version:
    description: 'Node version'
    default: '20'
outputs:
  artifact-path:
    description: 'Path to build output'
    value: ${{ steps.build.outputs.path }}
runs:
  using: 'composite'
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - id: build
      shell: bash
      run: |
        npm ci && npm run build
        echo "path=dist/" >> $GITHUB_OUTPUT
```

---

## 12. Environments and Deployments

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://myapp.com       # Shows as link in GitHub UI
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

Environments provide:
- **Required reviewers** — manual approval gate before job runs.
- **Wait timer** — delay before deployment starts.
- **Environment secrets/variables** — scoped to that environment only.
- **Deployment history** — tracked in GitHub UI.

Configure at: repo Settings → Environments.

---

## 13. Security Best Practices

```yaml
# 1. Always set minimum permissions
permissions:
  contents: read
  pull-requests: write

# 2. Pin third-party actions to full SHA (not just tag)
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# 3. Never inline secrets — always use ${{ secrets.X }}
# WRONG:  run: curl -H "Authorization: Bearer mytoken123"
# RIGHT:  run: curl -H "Authorization: Bearer $TOKEN"
#         env:
#           TOKEN: ${{ secrets.MY_TOKEN }}

# 4. Use OIDC instead of long-lived cloud credentials
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1
    # No static keys needed — GitHub mints a short-lived OIDC token

# 5. Avoid pull_request_target with untrusted code checkout
# 6. Use concurrency to cancel redundant runs
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

---

## 14. Common Patterns (Ready-to-Use)

### Node.js CI
```yaml
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: [18, 20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: npm
      - run: npm ci
      - run: npm test
```

### Docker build and push
```yaml
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### Release on tag push
```yaml
on:
  push:
    tags: ['v*']
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: make build
      - uses: softprops/action-gh-release@v2
        with:
          files: dist/*
```

---

## 15. Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---|---|---|
| Workflow not triggering | Branch filter mismatch or wrong event | Check `on:` filters; verify file is on default branch for some events |
| `Context access might be invalid` warning | Typo in context path | Check exact property names in Contexts docs |
| Secret shows as `***` but empty | Secret not set or wrong name | Verify in Settings → Secrets; names are case-sensitive |
| Job skipped unexpectedly | `if:` expression evaluates false | Debug with `${{ toJSON(github) }}` step to inspect context |
| Cache never hits | Key mismatch | Print key with `echo` step; check `hashFiles()` path |
| Self-hosted runner offline | Agent not running | SSH to machine; `./run.sh` or check systemd service |
| Permission denied on GITHUB_TOKEN | Default permissions too restrictive | Add explicit `permissions:` block to job |
| `pull_request` can't access secrets | Fork PR security restriction | Use `pull_request_target` (with caution) or require approval |

### Enable debug logging
Add repository secret `ACTIONS_STEP_DEBUG = true` to get verbose step output.
Add `ACTIONS_RUNNER_DEBUG = true` for runner-level debug logs.

---

## 16. Glossary

| Term | Meaning |
|---|---|
| `GITHUB_TOKEN` | Auto-generated token scoped to the current repo/run |
| `workflow_call` | Event type that makes a workflow reusable by others |
| `workflow_dispatch` | Manual trigger, exposes inputs as UI form in GitHub |
| `needs:` | Job dependency declaration |
| `matrix:` | Run same job N times with different variable combinations |
| `concurrency:` | Cancel in-progress runs in the same group |
| `environment:` | Named deployment target with optional approval gates |
| `OIDC` | OpenID Connect — keyless cloud auth via short-lived tokens |
| `composite action` | Reusable action defined purely in YAML steps |
| `$GITHUB_OUTPUT` | File-based mechanism to set step outputs |
| `$GITHUB_ENV` | File-based mechanism to set env vars for subsequent steps |
| `artifact` | Files persisted from a run, downloadable or passed between jobs |
| `cache` | Persisted layer reused across runs to speed up installs |
| `runner group` | Collection of self-hosted runners with access policy |
