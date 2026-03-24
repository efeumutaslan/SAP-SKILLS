---
name: sap-devops-cicd
description: >
  SAP DevOps and CI/CD pipeline skill. Use when setting up SAP CI/CD service, configuring
  Jenkins/Piper pipelines, implementing transport management (gCTS/TMS), or automating
  ABAP/CAP deployments. If the user mentions SAP CI/CD, Piper, gCTS, transport management,
  SAP pipeline, or ABAP deployment automation, use this skill.
disable-model-invocation: true
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.1.0"
  last_verified: "2026-03-25"
---

# SAP DevOps & CI/CD

## Related Skills
- `sap-testing-quality` — Test automation integrated into pipelines
- `sap-kyma-runtime` — Kyma/Kubernetes deployment targets
- `sap-s4hana-extensibility` — ABAP transport and extension deployment

## Quick Start

**Choose your CI/CD approach:**

| Scenario | Tool | Best For |
|----------|------|----------|
| BTP apps (CAP, UI5, MTA) | SAP CI/CD Service | Managed, no infrastructure |
| Full custom pipelines | Project "Piper" + Jenkins | Enterprise, complex workflows |
| ABAP Cloud development | ABAP Environment Pipeline | BTP ABAP Environment |
| ABAP on-premise transport | gCTS (Git-enabled CTS) | Git-based ABAP transport |
| Multi-environment promotion | Cloud Transport Management (TMS) | BTP subaccount promotion |
| Kubernetes workloads | Helm + ArgoCD / Flux | Kyma GitOps |

**Minimal SAP CI/CD Service config (`.pipeline/config.yml`):**

```yaml
general:
  buildTool: "mta"
  productiveBranch: "main"

stages:
  Build:
    mtaBuildTool: "cloudMbt"
  Additional Unit Tests:
    npmExecuteScripts: true
    npmScripts:
      - "test"
  Acceptance:
    cloudFoundryDeploy: true
    cfApiEndpoint: "https://api.cf.eu10.hana.ondemand.com"
    cfOrg: "my-org"
    cfSpace: "dev"
  Release:
    cloudFoundryDeploy: true
    cfApiEndpoint: "https://api.cf.eu10.hana.ondemand.com"
    cfOrg: "my-org"
    cfSpace: "prod"
    tmsUpload: true
```

## Core Concepts

### SAP CI/CD Service (BTP Managed)
- **Managed Jenkins**: No infrastructure to maintain
- **Pre-configured stages**: Build → Test → Deploy → Release
- **Supported project types**: MTA, CAP, UI5, ABAP Environment, Kyma
- **Credential store**: SAP Credential Store integration for secrets
- **Webhook triggers**: GitHub, GitLab, Bitbucket, Azure DevOps

### Project "Piper" (Open Source)
- **Container-based steps**: Each pipeline step in a Docker container
- **Library + steps**: Reusable Groovy library for Jenkins
- **Step catalog**: 100+ steps for SAP-specific tasks
- **Extensible**: Custom steps in Groovy or shell scripts
- **Multi-cloud**: Deploy to CF, Kyma, Neo, on-premise

### Transport Management

| Tool | Scope | Mechanism |
|------|-------|-----------|
| CTS+ | On-premise cross-system | Transport requests (classic) |
| gCTS | On-premise Git-based | Git repos linked to transport layer |
| Cloud TMS | BTP subaccounts | Transport nodes + routes |
| ABAP Environment Pipeline | BTP ABAP | `abapEnvironmentPipeline` |

### gCTS (Git-enabled Change and Transport System)
- Links ABAP packages to Git repositories
- Push/pull ABAP objects as files (abapGit-compatible serialization)
- Transport-like import: clone → pull → activate
- SAP-delivered checks before import
- Works with GitHub, GitLab, Bitbucket (on-premise/cloud)

## Common Patterns

### Pattern 1: Jenkinsfile with Project Piper

```groovy
@Library('piper-lib-os') _

pipeline {
  agent any

  stages {
    stage('Build') {
      steps {
        mtaBuild script: this, buildTarget: 'CF'
      }
    }

    stage('Unit Tests') {
      steps {
        npmExecuteScripts script: this, runScripts: ['test']
      }
    }

    stage('Lint & ATC') {
      parallel {
        stage('ESLint') {
          steps {
            npmExecuteLint script: this
          }
        }
        stage('ABAP ATC') {
          steps {
            abapEnvironmentRunATCCheck script: this,
              atcConfig: '.atc/config.yml',
              host: 'https://my-abap-env.abap.eu10.hana.ondemand.com'
          }
        }
      }
    }

    stage('Deploy to Dev') {
      steps {
        cloudFoundryDeploy script: this,
          deployTool: 'mtaDeployPlugin',
          cfApiEndpoint: 'https://api.cf.eu10.hana.ondemand.com',
          cfOrg: 'my-org',
          cfSpace: 'dev',
          cfCredentialsId: 'cf-deploy-dev'
      }
    }

    stage('Integration Tests') {
      steps {
        npmExecuteScripts script: this, runScripts: ['test:integration']
      }
    }

    stage('Transport to QA') {
      when { branch 'main' }
      steps {
        tmsUpload script: this,
          nodeName: 'QA',
          credentialsId: 'tms-credentials',
          mtaPath: 'mta_archives/*.mtar'
      }
    }
  }

  post {
    failure {
      emailext subject: "Pipeline Failed: ${env.JOB_NAME}",
               body: "Check: ${env.BUILD_URL}",
               recipientProviders: [[$class: 'DevelopersRecipientProvider']]
    }
  }
}
```

### Pattern 2: MTA Build Configuration

```yaml
# mta.yaml
_schema-version: "3.1"
ID: my-cap-app
version: 1.0.0

modules:
  - name: my-cap-srv
    type: nodejs
    path: gen/srv
    parameters:
      buildpack: nodejs_buildpack
      memory: 256M
    requires:
      - name: my-hana
      - name: my-xsuaa

  - name: my-cap-db
    type: hdb
    path: gen/db
    requires:
      - name: my-hana

  - name: my-cap-ui
    type: html5
    path: app/
    build-parameters:
      builder: custom
      commands:
        - npm run build
      supported-platforms: []

resources:
  - name: my-hana
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: my-xsuaa
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
```

### Pattern 3: ABAP Environment Pipeline

```yaml
# .pipeline/config.yml for ABAP Environment
general:
  buildTool: ""
  productiveBranch: "main"

stages:
  "Prepare System":
    cfServiceInstance: "my-abap-instance"
    cfServiceKeyName: "pipeline-key"
  "Clone Repositories":
    repositories: "repositories.yml"
    strategy: "Clone"
  "ATC":
    atcConfig: ".atc/config.yml"
  "Build":
    abapAddonAssemblyKitEndpoint: "https://apps.support.sap.com"
  "Integration Tests":
    script: "npm run test:abap"
  "Publish":
    addonDescriptor: "addon.yml"
```

```yaml
# repositories.yml
repositories:
  - name: "/DMO/FLIGHT"
    branch: "main"
    commitID: ""
  - name: "ZCUSTOM_APP"
    branch: "main"
    commitID: ""
```

### Pattern 4: Cloud Transport Management Setup

```bash
# Create transport nodes
cf create-service transport-management standard tms-instance
cf create-service-key tms-instance tms-key

# Node topology: DEV → QA → PROD
# Configure via BTP Cockpit > Cloud Transport Management
# Or via TMS API:
curl -X POST "https://<tms-url>/v2/nodes" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "QA",
    "description": "Quality Assurance",
    "transportType": "MTA",
    "destination": "cf-qa-destination",
    "forwardMode": "MANUAL"
  }'
```

### Pattern 5: gCTS Repository Setup

```
Transaction: GCTS (or /sap/bc/cts_abapvcs/repository)

1. Create repository:
   - Repository name: Z_MY_APP
   - vSID: <system_sid>
   - URL: https://github.com/myorg/z-my-app.git
   - Branch: main
   - Package: Z_MY_APP

2. Clone repository (pulls code from Git → ABAP)

3. Development workflow:
   - Develop in ABAP (ADT/SE80)
   - Commit changes to local repo
   - Push to remote
   - Pull in target system → activate
```

### Pattern 6: GitHub Actions for SAP (Alternative to Jenkins)

```yaml
# .github/workflows/sap-cicd.yml
name: SAP CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install MBT
        run: npm install -g mbt

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Build MTA
        run: mbt build -t ./mta_archives

      - name: Deploy to CF (dev)
        if: github.ref == 'refs/heads/develop'
        uses: SAP/cf-cli-action@v1
        with:
          command: deploy mta_archives/*.mtar -f
        env:
          CF_API: ${{ secrets.CF_API }}
          CF_USERNAME: ${{ secrets.CF_USERNAME }}
          CF_PASSWORD: ${{ secrets.CF_PASSWORD }}
          CF_ORG: ${{ secrets.CF_ORG }}
          CF_SPACE: dev
```

## Error Catalog

| Error | Context | Root Cause | Fix |
|-------|---------|------------|-----|
| `MTA build failed: resolution error` | `mbt build` | Missing dependency or wrong module path | Check `mta.yaml` paths; run `npm install` before build |
| `CF deploy: insufficient memory` | `cf deploy` | MTA module exceeds space quota | Reduce `memory` in `mta.yaml` or increase space quota |
| `TMS upload: node not found` | `tmsUpload` | Wrong node name in pipeline config | Verify node name in Cloud TMS admin UI |
| `gCTS clone: HTTP 401` | gCTS clone | Git credentials expired | Update stored credentials in SM59 or GCTS config |
| `ATC: critical findings` | ATC quality gate | Code has priority-1 issues | Fix findings; P1 cannot be exempted |
| `Piper step not found` | Jenkins | Wrong Piper library version | Update `@Library('piper-lib-os')` version; check step name |

## Performance Tips

1. **Parallel stages** — Run lint, unit tests, and ATC checks in parallel in Jenkins
2. **MTA build cache** — Cache `node_modules` between builds; `mbt build` supports `--mtar` for incremental
3. **Selective testing** — Only run tests for changed modules; use Git diff to determine scope
4. **Lightweight deploy** — Use `cf push --strategy rolling` for zero-downtime; `blue-green` for critical
5. **TMS batch** — Group related MTAs in a single transport; reduces approval overhead
6. **gCTS selective pull** — Pull only changed packages, not entire repository
7. **Pipeline-as-code** — Store `.pipeline/config.yml` in Git; version pipeline config with app code

## Gotchas

- **SAP CI/CD Service limitations**: No custom Docker images; limited to pre-built steps — use Piper for full flexibility
- **MTA archive size**: Max 1.5 GB for CF deploy; split large apps into multiple MTAs
- **gCTS vs. abapGit**: gCTS is SAP-supported transport tool; abapGit is community — gCTS uses CTS mechanisms, abapGit bypasses them
- **TMS node credentials**: Destination service credentials must be maintained per CF space/subaccount
- **Branch strategy**: SAP CI/CD service only supports one productive branch; use feature branches → develop → main flow
- **ABAP pipeline timing**: `Prepare System` can take 15-30 min for ABAP instance provisioning; use persistent instances for faster pipelines
