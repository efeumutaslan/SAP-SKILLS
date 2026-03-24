---
name: sap-kyma-runtime
description: |
  SAP BTP Kyma Runtime skill for Kubernetes-based extension development. Use when: deploying
  microservices to Kyma, creating Kubernetes workloads on SAP BTP, configuring Kyma Functions
  (serverless), setting up API Rules and service bindings, implementing event-driven extensions
  with SAP Event Mesh, managing Kyma modules, working with Istio service mesh on BTP, building
  side-by-side extensions on Kubernetes, or integrating Kyma with S/4HANA and other SAP systems.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP BTP Kyma Runtime

## Related Skills
- `sap-s4hana-extensibility` — S/4HANA events and APIs consumed by Kyma extensions
- `sap-devops-cicd` — CI/CD pipelines for Kyma deployments
- `sap-security-authorization` — XSUAA/IAS integration for Kyma workloads

## Quick Start

**Choose your extension pattern:**

| Scenario | Approach | Key Artifact |
|----------|----------|-------------|
| Lightweight webhook / event handler | Kyma Function (serverless) | `Function` CR |
| Full microservice | Kubernetes Deployment | `Deployment` + `Service` + `APIRule` |
| Scheduled job | Kubernetes CronJob | `CronJob` CR |
| Event-driven extension | Function + Event subscription | `Subscription` CR |
| Helm-based app | Helm chart | `Chart.yaml` + templates |

**Minimal Kyma Function:**

```yaml
apiVersion: serverless.kyma-project.io/v1alpha2
kind: Function
metadata:
  name: order-handler
  namespace: default
spec:
  runtime: nodejs20
  source:
    inline:
      source: |
        module.exports = {
          main: async function (event, context) {
            const order = event.data;
            console.log('Order received:', order.OrderID);
            return { statusCode: 200, body: { status: 'processed' } };
          }
        };
      dependencies: |
        { "name": "order-handler", "version": "1.0.0", "dependencies": {} }
```

## Core Concepts

### Kyma Architecture on BTP
- **Kyma modules**: Modular capabilities (Serverless, Istio, API Gateway, Eventing) enabled per cluster
- **BTP Service Operator**: Provisions BTP services (XSUAA, HANA, Destination) as Kubernetes secrets
- **Istio service mesh**: Mutual TLS, traffic management, observability built-in
- **Kyma Dashboard**: Web UI for managing resources (alternative to kubectl)

### Key Custom Resources

| CR | Purpose | Module |
|----|---------|--------|
| `Function` | Serverless function | Serverless |
| `APIRule` | Expose service externally (Istio Gateway) | API Gateway |
| `Subscription` | Subscribe to SAP/custom events | Eventing |
| `ServiceInstance` | Provision BTP service | BTP Operator |
| `ServiceBinding` | Bind BTP service to workload | BTP Operator |

### Namespace Strategy
- `default` — Quick prototyping only
- `production` / `staging` — Separate by environment
- One namespace per bounded context for microservice architectures
- Label namespaces with `istio-injection=enabled` for mesh

## Common Patterns

### Pattern 1: Microservice with BTP Service Binding

```yaml
# service-instance.yaml — provision XSUAA
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: xsuaa-instance
spec:
  serviceOfferingName: xsuaa
  servicePlanName: application
  parameters:
    xsappname: order-service
    tenant-mode: dedicated
    scopes:
      - name: $XSAPPNAME.OrderRead
        description: Read orders
    role-templates:
      - name: OrderViewer
        scope-references:
          - $XSAPPNAME.OrderRead
---
# service-binding.yaml
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: xsuaa-binding
spec:
  serviceInstanceName: xsuaa-instance
  secretName: xsuaa-credentials
```

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
        - name: order-service
          image: myregistry.io/order-service:1.0.0
          ports:
            - containerPort: 8080
          envFrom:
            - secretRef:
                name: xsuaa-credentials
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
    - port: 80
      targetPort: 8080
```

### Pattern 2: API Rule (External Exposure)

```yaml
apiVersion: gateway.kyma-project.io/v1beta1
kind: APIRule
metadata:
  name: order-api
spec:
  host: order-api
  service:
    name: order-service
    port: 80
  gateway: kyma-system/kyma-gateway
  rules:
    - path: /orders.*
      methods: ["GET", "POST"]
      accessStrategies:
        - handler: jwt
          config:
            jwks_urls:
              - https://<subaccount>.authentication.<region>.hana.ondemand.com/token_keys
            trusted_issuers:
              - https://<subaccount>.authentication.<region>.hana.ondemand.com
    - path: /health
      methods: ["GET"]
      accessStrategies:
        - handler: noop
```

### Pattern 3: Event-Driven Extension (S/4HANA Events)

```yaml
apiVersion: eventing.kyma-project.io/v1alpha2
kind: Subscription
metadata:
  name: order-created-sub
spec:
  sink: http://order-handler.default.svc.cluster.local
  source: sap.s4.beh/ER9
  types:
    - sap.s4.beh.businesspartner.v1.BusinessPartner.Created.v1
  typeMatching: standard
```

### Pattern 4: Destination Service Access

```yaml
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: dest-instance
spec:
  serviceOfferingName: destination
  servicePlanName: lite
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: dest-binding
spec:
  serviceInstanceName: dest-instance
  secretName: dest-credentials
```

```javascript
// Node.js — call S/4HANA via Destination Service
const { getDestination, executeHttpRequest } = require('@sap-cloud-sdk/connectivity');

async function getBusinessPartners() {
  const dest = await getDestination({ destinationName: 'S4HANA_SYSTEM' });
  const response = await executeHttpRequest(dest, {
    method: 'GET',
    url: '/sap/opu/odata/sap/API_BUSINESS_PARTNER/A_BusinessPartner?$top=10'
  });
  return response.data;
}
```

### Pattern 5: Helm Chart Deployment

```
my-extension/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── apirule.yaml
    └── service-binding.yaml
```

```bash
# Deploy with Helm
helm upgrade --install my-extension ./my-extension \
  --namespace production \
  --set image.tag=1.2.0 \
  --set replicas=3
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `Function CrashLoopBackOff` | Runtime error in function code | Syntax error or missing dependency | Check logs: `kubectl logs -n default -l serverless.kyma-project.io/function-name=<name>` |
| `APIRule ERROR` | `VirtualService creation failed` | Duplicate host or invalid gateway | Ensure unique host; verify gateway exists: `kubectl get gateways -n kyma-system` |
| `ServiceBinding failed` | `Could not find service instance` | Instance not ready or wrong name | Check `kubectl get serviceinstances`; wait for `Ready` status |
| `Subscription NATS error` | `No events received` | Wrong event type string or source | Match exact type from SAP Event Catalog; check eventing module is enabled |
| `ImagePullBackOff` | `unauthorized: authentication required` | Registry credentials missing | Create `imagePullSecret` and reference in Deployment spec |
| `OOMKilled` | Container killed by OOM | Memory limit too low | Increase `resources.limits.memory`; profile actual usage first |

## Performance Tips

1. **Right-size resources** — Start with `100m` CPU / `128Mi` memory, scale based on metrics
2. **HPA for autoscaling** — Use `HorizontalPodAutoscaler` on CPU/memory or custom metrics
3. **Function cold starts** — Set `minReplicas: 1` for latency-sensitive Functions
4. **Connection pooling** — Reuse HTTP clients and DB connections across invocations
5. **Istio sidecar** — Adds ~20ms latency per hop; disable for internal batch jobs if acceptable
6. **Image size** — Use distroless/alpine base images; smaller image = faster pull = faster scaling
7. **Pod disruption budgets** — Set `PodDisruptionBudget` for critical services during node upgrades

## Gotchas

- **Kyma module enablement**: Serverless, Eventing, API Gateway are separate modules — enable them in BTP Cockpit or via `Kyma` CR before use
- **Function source size limit**: Inline source max ~1MB; use Git source for larger codebases
- **Secret rotation**: BTP Service Operator does NOT auto-rotate secrets; delete and recreate ServiceBinding to refresh
- **Network policies**: By default, all pods can communicate; add `NetworkPolicy` for production isolation
- **Kyma trial limitations**: 14-day expiry, limited resources, no custom domains
