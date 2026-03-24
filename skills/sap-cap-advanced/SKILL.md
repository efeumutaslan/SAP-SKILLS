---
name: sap-cap-advanced
description: >
  Advanced SAP CAP skill for enterprise patterns. Use when building multi-tenant CAP apps,
  deploying to Kyma, implementing XSUAA/IAS auth, advanced CDS modeling, or CAP remote
  services. If the user mentions CAP multitenancy, CAP Kyma deploy, mtxs, CAP extensibility,
  or advanced CDS aspects/compositions, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# Advanced CAP — Multitenancy, Kyma & Enterprise Patterns

## Related Skills
- `sap-hana-cloud` — HANA Cloud as CAP persistence layer
- `sap-kyma-runtime` — Deploying CAP on Kyma/Kubernetes
- `sap-security-authorization` — XSUAA/IAS integration with CAP
- `sap-event-mesh` — CAP messaging with Event Mesh

## Quick Start

**Advanced CAP project setup:**

```bash
# Create CAP project with advanced features
cds init my-project --add hana,xsuaa,multitenancy,approuter,helm

# Add individual features
cds add hana           # HANA Cloud persistence
cds add xsuaa          # Authentication
cds add multitenancy   # SaaS multitenancy
cds add extensibility  # Tenant extensions
cds add helm           # Kyma/K8s deployment
cds add mtx            # MTX sidecar for tenant management
cds add messaging      # Event Mesh integration
cds add toggles        # Feature toggles
```

## Core Concepts

### CAP Multitenancy Architecture
```
                    ┌─────────────────────────┐
                    │    SaaS Application      │
                    │  (CAP + MTX Sidecar)     │
                    └──────────┬──────────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
     ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
     │ HDI Tenant A │ │ HDI Tenant B │ │ HDI Tenant C │
     │ (Schema A)   │ │ (Schema B)   │ │ (Schema C)   │
     └──────────────┘ └──────────────┘ └──────────────┘
              │                │                 │
              └────────────────┼─────────────────┘
                               ▼
                    ┌──────────────────┐
                    │  HANA Cloud DB    │
                    └──────────────────┘
```

### CAP Deployment Targets
| Target | Command | Artifacts |
|--------|---------|-----------|
| Cloud Foundry | `cds build --for cf` | `mta.yaml` → `cf deploy` |
| Kyma/K8s | `cds build --for kyma` | Helm chart → `helm upgrade` |
| Hybrid (local+cloud DB) | `cds bind` + `cds watch` | Local app + remote HANA |

### CDS Advanced Modeling Features
| Feature | Use Case |
|---------|----------|
| **Aspects** | Reusable field sets (managed, temporal, cuid) |
| **Compositions** | Document structures (header→items) |
| **Associations** | Cross-entity navigation |
| **Projections** | Service-level views (rename, exclude, redirect) |
| **Temporal data** | Bitemporal tables (valid-from/to, system time) |
| **Localized data** | Multi-language texts (auto-generated `_texts` table) |
| **Extensibility** | Tenant-specific model extensions |

## Common Patterns

### Pattern 1: Multitenancy Setup

```json
// package.json — MTX configuration
{
  "cds": {
    "requires": {
      "multitenancy": true,
      "extensibility": true,
      "toggles": true,
      "[production]": {
        "db": { "kind": "hana", "deploy-format": "hdbtable" },
        "auth": { "kind": "xsuaa" }
      }
    },
    "mtx": {
      "element-prefix": ["Z_", "z_"],
      "namespace-blocklist": ["com.sap.", "sap."],
      "extension-allowlist": [
        { "for": ["my.bookshop.Books"], "new-fields": 5 },
        { "for": ["my.bookshop.Authors"], "new-fields": 3 }
      ]
    }
  }
}
```

```javascript
// srv/tenant-provisioning.js — Custom tenant lifecycle
const cds = require('@sap/cds');

module.exports = class TenantProvisioning extends cds.ApplicationService {
  async init() {
    this.on('CREATE', 'tenant', async (req, next) => {
      const { subscribedTenantId, subscribedSubdomain } = req.data;
      console.log(`Provisioning tenant: ${subscribedTenantId}`);

      // Standard HDI container creation
      await next();

      // Custom post-provisioning (seed data, config)
      await this.seedTenantData(subscribedTenantId);
    });

    this.on('DELETE', 'tenant', async (req, next) => {
      const { subscribedTenantId } = req.data;
      console.log(`Deprovisioning tenant: ${subscribedTenantId}`);

      // Custom cleanup before HDI container deletion
      await this.archiveTenantData(subscribedTenantId);
      await next();
    });

    await super.init();
  }

  async seedTenantData(tenantId) {
    const db = await cds.connect.to('db');
    const { Configurations } = db.entities('my.app');
    await db.run(INSERT.into(Configurations).entries([
      { key: 'CURRENCY', value: 'EUR' },
      { key: 'LANGUAGE', value: 'EN' }
    ]));
  }
};
```

### Pattern 2: CAP + Kyma Helm Deployment

```yaml
# chart/values.yaml
global:
  domain: my-cluster.kyma.ondemand.com
  imagePullSecret:
    name: docker-registry-secret

srv:
  image:
    repository: my-registry.io/my-app-srv
    tag: latest
  bindings:
    db:
      serviceInstanceName: hana-hdi
    auth:
      serviceInstanceName: xsuaa-instance
  resources:
    limits:
      memory: 512Mi
      cpu: 500m
    requests:
      memory: 256Mi
      cpu: 100m

hana-deployer:
  image:
    repository: my-registry.io/my-app-hana-deployer
    tag: latest
  bindings:
    hana:
      serviceInstanceName: hana-hdi

html5-apps-deployer:
  image:
    repository: my-registry.io/my-app-html5-deployer
    tag: latest
```

```bash
# Build and deploy to Kyma
cds build --for kyma
docker build -t my-registry.io/my-app-srv:latest -f gen/srv/Dockerfile .
docker push my-registry.io/my-app-srv:latest
helm upgrade --install my-app ./chart \
  --namespace my-namespace \
  --set-file xsuaa.jsonParameters=xs-security.json
```

### Pattern 3: Remote Service Integration (Mashup)

```cds
// srv/external/API_BUSINESS_PARTNER.cds (imported)
// cds import API_BUSINESS_PARTNER --from <edmx-url>

using { API_BUSINESS_PARTNER as bupa } from './external/API_BUSINESS_PARTNER';

// srv/mashup-service.cds — Combine local + remote
service MashupService {
  // Local entity
  entity Orders as projection on my.Orders {
    *, customer: redirected to Customers
  };

  // Remote entity (federated from S/4HANA)
  @readonly entity Customers as projection on bupa.A_BusinessPartner {
    key BusinessPartner as ID,
    BusinessPartnerFullName as name,
    to_BusinessPartnerAddress as addresses
  };
}
```

```javascript
// srv/mashup-service.js — Remote service handler
const cds = require('@sap/cds');

module.exports = class MashupService extends cds.ApplicationService {
  async init() {
    const bupa = await cds.connect.to('API_BUSINESS_PARTNER');

    // Delegate reads to remote service
    this.on('READ', 'Customers', (req) => bupa.run(req.query));

    // Enrich local orders with remote customer data
    this.after('READ', 'Orders', async (orders) => {
      const customerIds = [...new Set(orders.map(o => o.customer_ID))];
      if (customerIds.length === 0) return;

      const customers = await bupa.run(
        SELECT.from('A_BusinessPartner')
          .where({ BusinessPartner: { in: customerIds } })
          .columns('BusinessPartner', 'BusinessPartnerFullName')
      );

      const customerMap = new Map(customers.map(c => [c.BusinessPartner, c]));
      for (const order of orders) {
        order.customerName = customerMap.get(order.customer_ID)?.BusinessPartnerFullName;
      }
    });

    await super.init();
  }
};
```

### Pattern 4: Advanced Authorization

```cds
// srv/admin-service.cds
@requires: 'authenticated-user'
service AdminService {

  @restrict: [
    { grant: 'READ',   to: 'Viewer' },
    { grant: 'WRITE',  to: 'Editor' },
    { grant: '*',      to: 'Admin' }
  ]
  entity Products as projection on my.Products;

  // Instance-based auth (row-level)
  @restrict: [
    { grant: 'READ',  to: 'SalesRep', where: 'region = $user.region' },
    { grant: '*',     to: 'SalesManager' }
  ]
  entity SalesOrders as projection on my.SalesOrders;
}
```

```json
// xs-security.json
{
  "xsappname": "my-app",
  "tenant-mode": "shared",
  "scopes": [
    { "name": "$XSAPPNAME.Viewer", "description": "Read access" },
    { "name": "$XSAPPNAME.Editor", "description": "Write access" },
    { "name": "$XSAPPNAME.Admin",  "description": "Full access" }
  ],
  "role-templates": [
    {
      "name": "Viewer",
      "scope-references": ["$XSAPPNAME.Viewer"],
      "attribute-references": [{ "name": "region" }]
    },
    {
      "name": "Editor",
      "scope-references": ["$XSAPPNAME.Viewer", "$XSAPPNAME.Editor"],
      "attribute-references": [{ "name": "region" }]
    },
    {
      "name": "Admin",
      "scope-references": ["$XSAPPNAME.Admin"]
    }
  ]
}
```

### Pattern 5: CAP with HANA Native Artifacts

```cds
// db/schema.cds — Use HANA-specific features
using { managed, cuid } from '@sap/cds/common';

@cds.persistence.journal  // Enable temporal tables
entity AuditLog : cuid, managed {
  action    : String(50);
  entity    : String(100);
  oldValue  : LargeString;
  newValue  : LargeString;
}

// Use HANA calculation view
@cds.persistence.exists  // Don't generate table, it exists in HANA
entity SalesDashboard {
  key region    : String(10);
  totalRevenue  : Decimal(15,2);
  orderCount    : Integer;
  avgOrderValue : Decimal(15,2);
}
```

```json
// db/src/CV_SALES_DASHBOARD.hdbcalculationview
// (Graphical calculation view created in BAS)
// Referenced by @cds.persistence.exists entity above
```

```sql
-- db/src/SP_COMPLEX_CALC.hdbprocedure
PROCEDURE "SP_COMPLEX_CALC" (
  IN iv_year INTEGER,
  OUT et_result TABLE (region NVARCHAR(10), revenue DECIMAL(15,2))
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
READS SQL DATA
AS
BEGIN
  et_result = SELECT region, SUM(amount) AS revenue
              FROM "MY_APP_ORDERS"
              WHERE YEAR("createdAt") = :iv_year
              GROUP BY region;
END;
```

### Pattern 6: CAP Feature Toggles

```javascript
// srv/feature-service.js
const cds = require('@sap/cds');
const toggles = require('@sap/cds-mtx/toggles');

module.exports = class FeatureService extends cds.ApplicationService {
  async init() {
    this.before('CREATE', 'Orders', async (req) => {
      // Check if new pricing engine is enabled for this tenant
      if (await toggles.isEnabled('new-pricing-engine', req.tenant)) {
        req.data.price = await this.calculateNewPrice(req.data);
      } else {
        req.data.price = await this.calculateLegacyPrice(req.data);
      }
    });

    await super.init();
  }
};
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `TENANT_NOT_FOUND` | No HDI container for tenant | Tenant not provisioned | Run tenant subscription; check MTX sidecar logs |
| `CDS_COMPILE_ERROR` | Model compilation failed | Invalid CDS syntax or circular dependency | Run `cds compile --to sql` locally to debug |
| `XSUAA: Forbidden` | JWT scope mismatch | Missing role assignment | Assign role collection to user in BTP cockpit |
| `Remote service: 401` | Destination auth failed | Expired OAuth token or wrong destination config | Check BTP destination; regenerate credentials |
| `HDI deploy: 409` | Container already exists | Duplicate tenant provisioning | Check MTX sidecar idempotency; clean up orphans |
| Helm: `ImagePullBackOff` | Cannot pull container image | Wrong registry or missing secret | Verify image exists; check imagePullSecret |
| `cds bind: Service not found` | Binding resolution failed | Service key missing or wrong name | Run `cf service-key <instance> <key>` to verify |
| `HANA: Column store error` | Schema deployment failed | Incompatible schema evolution | Check `.hdbmigrationtable` for migration steps |

## Performance Tips

1. **Batch remote calls** — Use `$batch` for multiple remote service requests; CAP auto-batches with `cds.ql`
2. **Projection pushdown** — Use `columns()` in queries; CAP pushes column selection to HANA
3. **Expand wisely** — `$expand` with deep nesting causes N+1; prefer flat queries with client-side assembly
4. **Connection pooling** — CAP pools HANA connections by default; tune `pool.max` for high-concurrency
5. **MTX sidecar** — Deploy MTX as separate microservice for tenant operations (don't block main app)
6. **Streaming** — Use `$top/$skip` pagination for large result sets; CAP supports `@odata.maxpagesize`
7. **HANA artifacts** — For complex analytics, use calculation views (`@cds.persistence.exists`) over CDS views

## Validation Workflow

Before deploying a CAP project, validate structure and configuration:

```bash
bash scripts/validate-cap-project.sh .
```

**Deploy checklist:**
- [ ] CDS models compile (`cds build`)
- [ ] Tests pass (`npm test`)
- [ ] Auth annotations present on all services
- [ ] mta.yaml or Helm chart configured for target platform
- [ ] No hardcoded credentials in code

## Gotchas

- **MTX sidecar version**: Must match `@sap/cds` version exactly; mismatch causes tenant operations to fail
- **Kyma vs CF bindings**: Kyma uses service bindings as Kubernetes secrets; CF uses VCAP_SERVICES
- **Remote service quotas**: BTP destination connections have concurrency limits; implement circuit breaker
- **Schema evolution**: HDI doesn't support all schema changes (e.g., narrowing column types); plan migrations
- **cds build output**: `--for cf` generates `mta.yaml`; `--for kyma` generates Helm chart — different structures
- **Feature toggles**: Require `@sap/cds-mtx` package and MTX sidecar; not available in single-tenant mode

## MCP Server Integration

For AI-assisted CAP development, add to your `.mcp.json`:

```json
{
  "mcpServers": {
    "cap-mcp": {
      "command": "npx", "args": ["-y", "@cap-js/mcp-server"]
    },
    "fiori-mcp": {
      "command": "npx", "args": ["-y", "@sap-ux/fiori-mcp-server"]
    }
  }
}
```

- **CAP MCP** (official): CDS model search + CAP documentation search
- **Fiori MCP** (official): Fiori elements app generation, annotation editing
