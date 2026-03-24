# CAP Multitenancy Checklist

## Architecture Requirements

| Item | Description | Status |
|------|-------------|--------|
| SAAS Registry | Subscribe via `@sap/cds-mtxs` | Required |
| Service Manager | Provision HDI containers per tenant | Required |
| XSUAA | Tenant-aware OAuth2 tokens | Required |
| Approuter | Route `<tenant>.app.domain` → app | Required |
| Event Mesh | Optional: tenant-specific events | Optional |

## cds-mtxs Setup

```json
// package.json
{
  "cds": {
    "requires": {
      "multitenancy": true,
      "extensibility": true,
      "toggles": true
    },
    "mtx": {
      "element-prefix": ["Z_", "z_"],
      "namespace-blocklist": ["com.sap."]
    }
  }
}
```

## Tenant Lifecycle Hooks

```javascript
// srv/provisioning.js
module.exports = (service) => {
  service.on('UPDATE', 'tenant', async (req, next) => {
    // Custom logic on subscription
    const { subscribedSubdomain, subscribedTenantId } = req.data;
    console.log(`Provisioning tenant: ${subscribedTenantId}`);
    await next();
    // Post-provision: seed data, apply defaults
  });

  service.on('DELETE', 'tenant', async (req, next) => {
    const { subscribedTenantId } = req.data;
    console.log(`Deprovisioning tenant: ${subscribedTenantId}`);
    await next();
  });
};
```

## Tenant-Aware Data Access

```javascript
// cds.context.tenant is set automatically from JWT
// All DB queries are scoped to tenant's HDI container

// Manual tenant context (for background jobs)
await cds.tx({ tenant: 'tenant-guid' }, async (tx) => {
  const orders = await tx.run(SELECT.from('Orders'));
});
```

## Key mta.yaml Resources

```yaml
resources:
  - name: saas-registry
    type: org.cloudfoundry.managed-service
    parameters:
      service: saas-registry
      service-plan: application
      config:
        xsappname: myapp
        appUrls:
          getDependencies: ~{srv-api/srv-url}/-/cds/saas-provisioning/dependencies
          onSubscription: ~{srv-api/srv-url}/-/cds/saas-provisioning/tenant/{tenantId}

  - name: service-manager
    type: org.cloudfoundry.managed-service
    parameters:
      service: service-manager
      service-plan: container
```

## Testing Multitenancy Locally

```bash
# Start with mock tenants
cds watch --profile hybrid

# Simulate tenant header
curl -H "x-tenant-id: t1" http://localhost:4004/odata/v4/catalog/Orders
```

## Common Pitfalls

| Issue | Cause | Fix |
|-------|-------|-----|
| 403 on subscribe | Missing SAAS Registry config | Check `appUrls` in mta.yaml |
| Empty DB after subscribe | HDI deploy failed | Check service-manager logs |
| Wrong tenant data | Missing JWT validation | Ensure XSUAA bound correctly |
| Extension rejected | Blocked namespace | Update `namespace-blocklist` |
| Slow provisioning | Large initial data | Use async provisioning pattern |
