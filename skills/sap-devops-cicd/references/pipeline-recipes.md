# SAP CI/CD Pipeline Recipes

## Recipe 1: ABAP (gCTS + ATC) — GitHub Actions

```yaml
name: ABAP CI Pipeline
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  atc-check:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger ATC Run
        uses: actions/http-request@v2
        with:
          url: "${{ secrets.SAP_HOST }}/sap/bc/adt/atc/runs"
          method: POST
          headers: |
            Authorization: Basic ${{ secrets.SAP_AUTH }}
            Content-Type: application/xml
          body: |
            <atcRun>
              <objectSet>
                <softwareComponent name="${{ vars.ABAP_PACKAGE }}"/>
              </objectSet>
            </atcRun>

      - name: Check ATC Results
        run: |
          # Poll for results and fail if Priority 1 findings exist
          RESULT=$(curl -s -H "Authorization: Basic ${{ secrets.SAP_AUTH }}" \
            "${{ secrets.SAP_HOST }}/sap/bc/adt/atc/runs/$RUN_ID/results")
          P1_COUNT=$(echo "$RESULT" | grep -c 'priority="1"')
          if [ "$P1_COUNT" -gt 0 ]; then
            echo "❌ $P1_COUNT Priority 1 ATC findings — failing build"
            exit 1
          fi
```

## Recipe 2: CAP Full-Stack — GitHub Actions

```yaml
name: CAP CI/CD
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Unit Tests
        run: npm test -- --coverage

      - name: Build MTA
        run: |
          npm install -g mbt
          mbt build -p=cf

      - name: Upload MTA
        uses: actions/upload-artifact@v4
        with:
          name: mta-archive
          path: mta_archives/*.mtar

  deploy-dev:
    needs: build-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: development
    steps:
      - name: Download MTA
        uses: actions/download-artifact@v4
        with:
          name: mta-archive

      - name: Deploy to CF
        run: |
          cf login -a ${{ secrets.CF_API }} -u ${{ secrets.CF_USER }} \
            -p ${{ secrets.CF_PASSWORD }} -o ${{ secrets.CF_ORG }} \
            -s ${{ secrets.CF_SPACE_DEV }}
          cf deploy *.mtar --retries 1
```

## Recipe 3: UI5/Fiori — Jenkins

```groovy
// Jenkinsfile
@Library('piper-lib-os') _

pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        sh 'npm ci'
        sh 'npm run build'
      }
    }
    stage('Lint') {
      steps {
        sh 'npx @sap/ux-ui5-tooling lint'
      }
    }
    stage('Unit Test') {
      steps {
        sh 'npx karma start karma.conf.js --single-run'
      }
    }
    stage('OPA5 Test') {
      steps {
        sh 'npx karma start karma-opa5.conf.js --single-run'
      }
    }
    stage('Deploy') {
      when { branch 'main' }
      steps {
        sapUploadToHtml5Repo script: this,
          archivePath: 'dist/*.zip',
          applicationName: 'my-fiori-app'
      }
    }
  }
}
```

## Recipe 4: ABAP + abapGit — Azure DevOps

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main, develop]

pool:
  vmImage: ubuntu-latest

stages:
  - stage: Validate
    jobs:
      - job: SyntaxCheck
        steps:
          - script: |
              # Trigger syntax check via ADT API
              curl -X POST \
                -H "Authorization: Basic $(SAP_AUTH)" \
                -H "Content-Type: application/xml" \
                "$(SAP_HOST)/sap/bc/adt/programs/syntax_check" \
                -d '<syntaxCheck><object url="/sap/bc/adt/packages/$(PACKAGE)"/></syntaxCheck>'

  - stage: ATC
    dependsOn: Validate
    jobs:
      - job: ATCRun
        steps:
          - script: |
              # Run ATC and check results
              RUN_ID=$(curl -s -X POST \
                -H "Authorization: Basic $(SAP_AUTH)" \
                "$(SAP_HOST)/sap/bc/adt/atc/runs" \
                -d '<atcRun><objectSet><package name="$(PACKAGE)"/></objectSet></atcRun>' \
                | grep -oP 'id="\K[^"]+')
              echo "ATC Run: $RUN_ID"

  - stage: Transport
    dependsOn: ATC
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - job: ReleaseTransport
        steps:
          - script: |
              # Release transport request
              curl -X POST \
                -H "Authorization: Basic $(SAP_AUTH)" \
                "$(SAP_HOST)/sap/bc/adt/cts/transportrequests/$(TRANSPORT)/release"
```

## Recipe 5: BTP CI/CD Service (Managed)

```yaml
# .pipeline/config.yml (SAP BTP CI/CD Service)
general:
  buildTool: mta

stages:
  Build:
    mtaBuild:
      buildTarget: CF

  Additional Unit Tests:
    npmExecuteScripts:
      runScripts:
        - test

  Acceptance:
    cloudFoundryDeploy:
      deployTool: mtaDeployPlugin
      cfApiEndpoint: https://api.cf.eu10.hana.ondemand.com
      cfOrg: my-org
      cfSpace: dev
      cfCredentialsId: cf-credentials

  Release:
    cloudFoundryDeploy:
      cfSpace: prod
    tmsUpload:
      nodeName: PRD
      credentialsId: tms-credentials
```
