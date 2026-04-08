---
name: sap-odata
description: >
  OData protocol skill for SAP — both service design (OData v2/v4 via RAP, CAP, SEGW) and
  consumption (UI5, Fiori, CAP remote services, external clients). Use when designing OData
  services, building query options ($filter, $expand, $select, $orderby, $top, $skip, $search,
  $count), handling CSRF tokens, batch requests, etags, or debugging OData errors. If the user
  mentions OData, $metadata, OData v2, OData v4, SEGW, service binding, batch request, CSRF, or
  OData filter syntax, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-04-08"
---

# OData Protocol for SAP — Design and Consumption

## Related Skills
- `sap-rap-comprehensive` — Primary way to build OData v4 services in modern ABAP
- `sap-cap-advanced` — Primary way to build OData v4 services in Node.js/Java on BTP
- `sap-ui5-fiori` — Biggest OData consumer in the SAP ecosystem
- `sap-integration-suite-advanced` — OData in iFlows, API Management, and B2B scenarios
- `sap-s4hana-extensibility` — Released OData APIs vs custom OData services

## Quick Start

**Check a service's metadata (what it exposes):**
```
GET /sap/opu/odata/sap/ZMY_SERVICE/$metadata       # OData v2
GET /odata/v4/my-service/$metadata                 # OData v4
```

**Query entities with common options:**
```
GET /Products?$filter=Price gt 100 and Category eq 'Electronics'
            &$select=ID,Name,Price
            &$expand=Supplier($select=Name,Country)
            &$orderby=Name asc
            &$top=20&$skip=0
            &$count=true
```

**Pick v2 or v4:**

| Decision | Choose |
|----------|--------|
| New greenfield backend | **v4** |
| Modern ABAP (RAP), CAP | **v4** (RAP v4 is default since 7.54) |
| Legacy SEGW in S/4 on-prem | **v2** (some SAP standard services are still v2) |
| Fiori Elements on S/4HANA 2023+ | **v4** preferred |
| UI5 consumer for legacy backend | **v2** (with `sap.ui.model.odata.v2.ODataModel`) |

## Core Concepts

### v2 vs v4 — critical differences

| Feature | OData v2 | OData v4 |
|---------|----------|----------|
| Key syntax | `/Products('HT-1001')` | `/Products(ID='HT-1001')` or `/Products('HT-1001')` |
| Filter on navigation | `$filter=Supplier/Name eq 'X'` | `$filter=Supplier/Name eq 'X'` (same) |
| Count | `/$count` or `$inlinecount=allpages` | `$count=true` |
| Batch format | `multipart/mixed` | `application/json` |
| Function import | `/GetProducts?name='X'` | `/getProducts(name='X')` |
| Action import | `POST /SubmitOrder` | `POST /submitOrder` |
| Deep insert | Supported | Supported |
| `$apply` | Not standard | Standard (aggregations) |
| JSON format | Verbose / light | Standard JSON |
| Type system | EDM types | EDM types (extended) |

### Entity Data Model (EDM) types

| Type | SQL equivalent | Notes |
|------|----------------|-------|
| `Edm.String` | VARCHAR/NVARCHAR | `MaxLength`, `Unicode` facets |
| `Edm.Int32` | INT | 32-bit signed |
| `Edm.Int64` | BIGINT | 64-bit signed |
| `Edm.Decimal` | DECIMAL | `Precision`, `Scale` facets |
| `Edm.Double` | DOUBLE | 64-bit float |
| `Edm.Boolean` | BOOLEAN | true/false |
| `Edm.DateTimeOffset` | TIMESTAMP WITH TZ | ISO 8601 with offset |
| `Edm.Date` | DATE | v4 only (v2 uses DateTime) |
| `Edm.TimeOfDay` | TIME | v4 only |
| `Edm.Guid` | UUID | Without hyphens in URLs |
| `Edm.Binary` | BLOB | Base64 in JSON |

### Service document structure
```
/                              # Service document — lists entity sets
/$metadata                     # EDMX — complete service description
/Products                      # Entity set
/Products('HT-1001')           # Entity
/Products('HT-1001')/Name      # Primitive property
/Products('HT-1001')/Supplier  # Navigation property
/Products/$count               # v4: entity count
```

## Common Patterns

### Pattern 1: Query options reference
```
# Select only specific fields (reduces payload)
?$select=ID,Name,Price

# Include related entities (JOIN)
?$expand=Supplier,Category
?$expand=Supplier($select=Name,Country)     # nested select
?$expand=Orders($filter=Status eq 'Open')    # nested filter (v4)

# Filter
?$filter=Price gt 100
?$filter=contains(Name, 'Pro')                # v4: contains, startswith, endswith
?$filter=substringof('Pro', Name)             # v2: substringof
?$filter=Category eq 'Electronics' and Price le 500
?$filter=Date ge 2026-01-01 and Date lt 2026-02-01   # v4 date
?$filter=Supplier/Country eq 'DE'             # navigation filter

# Sort
?$orderby=Name asc
?$orderby=Price desc, Name asc

# Pagination
?$top=20&$skip=40                             # rows 41-60

# Count
?$count=true                                  # v4
?$inlinecount=allpages                        # v2

# Search (v4, if service supports Capabilities.SearchRestrictions.Searchable)
?$search=laptop

# Aggregations (v4 with $apply)
?$apply=groupby((Category), aggregate(Price with sum as TotalPrice))
```

### Pattern 2: CRUD operations

```http
# CREATE
POST /Products
Content-Type: application/json
X-CSRF-Token: <token>

{
  "ID": "HT-9999",
  "Name": "New Product",
  "Price": 299.99
}

# READ
GET /Products('HT-1001')

# UPDATE (full replace)
PUT /Products('HT-1001')
Content-Type: application/json
If-Match: W/"etag-value"

{ "ID": "HT-1001", "Name": "Updated", "Price": 199.99 }

# PATCH (partial update) — preferred
PATCH /Products('HT-1001')
Content-Type: application/json
If-Match: W/"etag-value"

{ "Price": 199.99 }

# DELETE
DELETE /Products('HT-1001')
If-Match: W/"etag-value"
```

### Pattern 3: Batch request (v4 JSON batch)
```http
POST /$batch
Content-Type: application/json

{
  "requests": [
    { "id": "1", "method": "GET", "url": "Products('HT-1001')" },
    { "id": "2", "method": "GET", "url": "Suppliers('S-001')" },
    {
      "id": "3",
      "method": "PATCH",
      "url": "Products('HT-1001')",
      "headers": { "Content-Type": "application/json", "If-Match": "*" },
      "body": { "Price": 199.99 },
      "atomicityGroup": "tx1"
    }
  ]
}
```

### Pattern 4: CSRF token flow (write operations)
```http
# Step 1: Fetch token via any GET
GET /sap/opu/odata/sap/ZMY_SERVICE/
X-CSRF-Token: Fetch

# Response headers include:
X-CSRF-Token: abc123xyz
Set-Cookie: sap-XSRF_...

# Step 2: Use token + cookie in subsequent writes
POST /Products
X-CSRF-Token: abc123xyz
Cookie: sap-XSRF_...
```

UI5's ODataModel handles this automatically. Custom fetch clients must do it manually.

### Pattern 5: CAP OData service
```cds
// srv/products-service.cds
using { my.db.Products } from '../db/schema';

service ProductsService @(path: '/products') {
  entity Products as projection on my.db.Products;

  // Action
  action approveProduct(ID: String) returns String;

  // Function
  function productsOverStock(threshold: Integer) returns array of Products;
}
```

Exposes `GET /products/Products`, `POST /products/approveProduct`, etc. — automatically OData v4.

### Pattern 6: RAP projection as OData service
```abap
" Service definition (ZSD_PRODUCTS)
@EndUserText.label: 'Products Service'
define service ZSD_PRODUCTS {
  expose ZC_PRODUCT as Products;
  expose ZC_SUPPLIER as Suppliers;
}

" Service binding (ZSB_PRODUCTS_V4)
" Binding Type: OData V4 - UI
" Service Definition: ZSD_PRODUCTS
```

Published at `/sap/opu/odata4/sap/zsb_products_v4/srvd_a2x/sap/zsd_products/0001/`.

### Pattern 7: UI5 consumption
```javascript
// OData v4
const oModel = new sap.ui.model.odata.v4.ODataModel({
  serviceUrl: "/odata/v4/products/",
  synchronizationMode: "None",
  operationMode: "Server",
  autoExpandSelect: true
});

// Read
const oContext = oModel.bindContext("/Products('HT-1001')");
oContext.requestObject().then(oProduct => console.log(oProduct));

// Update (PATCH)
oContext.setProperty("Price", 199.99);
await oModel.submitBatch("$auto");

// Create
const oListBinding = oModel.bindList("/Products");
const oNewContext = oListBinding.create({ ID: "HT-9999", Name: "New" });
await oNewContext.created();
```

### Pattern 8: External client (fetch/axios)
```javascript
// Fetch CSRF token
const tokenRes = await fetch("/sap/opu/odata/sap/ZMY_SERVICE/", {
  headers: { "X-CSRF-Token": "Fetch" },
  credentials: "include"
});
const csrfToken = tokenRes.headers.get("x-csrf-token");

// Write with token
const createRes = await fetch("/sap/opu/odata/sap/ZMY_SERVICE/Products", {
  method: "POST",
  credentials: "include",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": csrfToken,
    "Accept": "application/json"
  },
  body: JSON.stringify({ ID: "HT-9999", Name: "New" })
});
```

## Error Catalog

| HTTP | Error | Cause | Fix |
|------|-------|-------|-----|
| 400 | `Invalid filter expression` | Wrong filter syntax or unknown property | Check property name case; `eq`/`ne`/`gt`/`lt` must be lowercase; strings need single quotes |
| 400 | `Could not parse URI` | Invalid key syntax, wrong v2 vs v4 | v2: `/Products('HT-1001')`; v4: `/Products(ID='HT-1001')` or `/Products('HT-1001')` |
| 401 | `Authentication failed` | Missing or invalid credentials | Add Basic Auth, form login, or OAuth token |
| 403 | `CSRF token validation failed` | Missing CSRF token on write | Fetch token via GET with `X-CSRF-Token: Fetch`, reuse on POST/PUT/PATCH/DELETE |
| 403 | `Not authorized` | User lacks permissions | Check role (PFCG for ABAP, XSUAA scopes for CAP/BTP) |
| 404 | `Resource not found` | Wrong URL or service not active | Check service is published; verify path; check `/$metadata` loads |
| 412 | `Precondition Failed` | Missing or stale `If-Match` etag | Include `If-Match: <etag>` from the last read |
| 428 | `Precondition Required` | etag required but not sent | Send `If-Match: *` to force update without etag check (if allowed) |
| 501 | `Not Implemented` | Function/feature not supported by service | Check `$metadata` — does the service declare the capability? |
| 500 | `/IWBEP/CX_MGW_BUSI_EXCEPTION` | Business logic error in SEGW data provider | Read the inner message; check backend logs (ST22 for ABAP dumps) |

## Performance Tips

1. **Always `$select` what you need** — never fetch full entities when you only need 3 columns.
2. **`$expand` is expensive** — prefer a second batch request over deep expands.
3. **Server-side paging with `$top` + `$skip`** — never load all rows; clients like UI5 do this automatically with `growing`.
4. **`$count=true`** — only request the count when the UI actually shows it.
5. **Batch write operations** — one `$batch` instead of N single calls reduces round-trip time dramatically.
6. **Use `PATCH`, not `PUT`** — PATCH sends only changed fields, PUT sends the whole entity.
7. **Index navigation property columns** — `$filter` on joined fields otherwise does full scans.
8. **`$apply` for aggregations (v4)** — let the server aggregate instead of fetching raw rows.
9. **Cache `$metadata`** — it rarely changes; UI5 does this automatically.
10. **Disable cursors for small result sets** — OData v4 `Capabilities.TopSupported` can be tuned.
11. **Projection CDS views** — at the DB layer, expose only the fields needed by OData.

## Gotchas

- **Single quotes for strings, no quotes for numbers** — `$filter=Name eq 'X'` vs `$filter=Price eq 100`.
- **Date literals differ** — v2: `datetime'2026-01-01T00:00:00'`; v4: `2026-01-01` (Date) or `2026-01-01T00:00:00Z` (DateTimeOffset).
- **URL encoding** — `$filter=Name eq 'O''Brien'` (apostrophe doubled), spaces as `%20`.
- **`$inlinecount` vs `$count`** — don't mix up; `$inlinecount=allpages` is v2, `$count=true` is v4.
- **Navigation property case sensitivity** — `$expand=Supplier` ≠ `$expand=supplier` in most services.
- **Action names** — v2 uses `GET` + function imports for side-effect-free, `POST` otherwise; v4 clearly separates Actions (`POST`) from Functions (`GET`).
- **Deep insert depth** — most backends limit to 2–3 levels.
- **Batch changesets** — atomic unit in v2 `$batch`; mistakes in one operation roll back the whole changeset.
- **Lambda operators (`any`, `all`)** — v4 only; v2 services ignore or error.
- **Key predicates with multiple fields** — `/Orders(OrderID=5,ItemID=1)` — order matters in some implementations.

## Debugging Workflow

1. **Always check `$metadata` first** — it's the source of truth for what's exposed.
2. **Use the Gateway Client (`/IWFND/GW_CLIENT`)** on ABAP — test requests with full headers/body.
3. **Browser DevTools → Network → XHR filter** — see the exact URL, headers, and response.
4. **Postman/Insomnia** — build requests manually, inspect auth headers.
5. **Enable trace in backend** — ABAP: `/IWFND/TRACES`; CAP: `DEBUG=odata*`.
6. **Metadata viewer tools** — [odata-debugger](https://github.com/SAP/odata-client-for-javascript) shows the service structure.

## References

- `references/query-options-cheatsheet.md` — All query options with examples
- `references/edm-types-reference.md` — EDM type catalog with literals and facets
- `references/odata-v2-vs-v4.md` — Side-by-side comparison for migration
- `templates/cap-service-template.cds` — CAP OData service skeleton
- `templates/rap-service-definition.asddls` — RAP service definition template

## MCP Server Integration

For OData development:
- `@cap-js/mcp-server` — CAP service design, OData metadata, CDS authoring
- `marianfoo/mcp-sap-docs` — SAP documentation lookup (OData SDK, ABAP OData)
- Vibing Steampunk MCP — ABAP Gateway service activation, SEGW operations

Install via `mcp-configs/fullstack-btp.json`.
