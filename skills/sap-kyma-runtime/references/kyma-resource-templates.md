# Kyma Runtime — Kubernetes Resource Reference

## Deployment + Service + HPA

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{APP_NAME}}
  labels:
    app: {{APP_NAME}}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: {{APP_NAME}}
  template:
    metadata:
      labels:
        app: {{APP_NAME}}
        sidecar.istio.io/inject: "true"
    spec:
      containers:
        - name: {{APP_NAME}}
          image: {{DOCKER_REGISTRY}}/{{APP_NAME}}:latest
          ports:
            - containerPort: 8080
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          env:
            - name: NODE_ENV
              value: production
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          volumeMounts:
            - name: sap-btp-bindings
              mountPath: /etc/secrets/sapbtp
              readOnly: true
      volumes:
        - name: sap-btp-bindings
          secret:
            secretName: {{APP_NAME}}-xsuaa-binding
---
apiVersion: v1
kind: Service
metadata:
  name: {{APP_NAME}}
spec:
  selector:
    app: {{APP_NAME}}
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{APP_NAME}}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{APP_NAME}}
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

## API Rule (Expose via Istio Gateway)

```yaml
apiVersion: gateway.kyma-project.io/v1beta1
kind: APIRule
metadata:
  name: {{APP_NAME}}
spec:
  gateway: kyma-gateway.kyma-system.svc.cluster.local
  host: {{APP_NAME}}.{{CLUSTER_DOMAIN}}
  service:
    name: {{APP_NAME}}
    port: 80
  rules:
    - path: /api/.*
      methods: ["GET", "POST", "PUT", "DELETE"]
      accessStrategies:
        - handler: jwt
          config:
            jwks_urls:
              - https://{{XSUAA_DOMAIN}}/token_keys
            trusted_issuers:
              - https://{{XSUAA_DOMAIN}}
    - path: /health
      methods: ["GET"]
      accessStrategies:
        - handler: noop
```

## BTP Service Binding (via BTP Operator)

```yaml
apiVersion: services.cloud.sap.com/v1
kind: ServiceInstance
metadata:
  name: {{APP_NAME}}-xsuaa
spec:
  serviceOfferingName: xsuaa
  servicePlanName: application
  parameters:
    xsappname: {{APP_NAME}}
    tenant-mode: dedicated
---
apiVersion: services.cloud.sap.com/v1
kind: ServiceBinding
metadata:
  name: {{APP_NAME}}-xsuaa-binding
spec:
  serviceInstanceName: {{APP_NAME}}-xsuaa
```

## Kyma Function (Serverless)

```yaml
apiVersion: serverless.kyma-project.io/v1alpha2
kind: Function
metadata:
  name: order-webhook
spec:
  runtime: nodejs20
  source:
    inline:
      source: |
        module.exports = {
          main: async (event, context) => {
            const order = JSON.parse(event.extensions.request.body);
            console.log('Received order:', order.SalesOrder);
            return { statusCode: 200, body: JSON.stringify({ status: 'ok' }) };
          }
        };
      dependencies: ""
  resourceConfiguration:
    function:
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          cpu: 200m
          memory: 256Mi
```

## Common kubectl Commands

```bash
# Check pods
kubectl get pods -l app={{APP_NAME}} -n {{NAMESPACE}}

# Logs
kubectl logs -l app={{APP_NAME}} -n {{NAMESPACE}} --tail=100 -f

# BTP service instances
kubectl get serviceinstances -n {{NAMESPACE}}

# API rules
kubectl get apirules -n {{NAMESPACE}}

# Restart deployment
kubectl rollout restart deployment/{{APP_NAME}} -n {{NAMESPACE}}
```
