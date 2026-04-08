# OData v2 vs v4 — Migration Reference

Side-by-side comparison for migrating services and clients from OData v2 to v4.

## Table of Contents

- [Decision Matrix](#decision-matrix)
- [URL Syntax Differences](#url-syntax-differences)
- [Query Option Differences](#query-option-differences)
- [Request/Response Format](#requestresponse-format)
- [Date/Time Handling](#datetime-handling)
- [Actions and Functions](#actions-and-functions)
- [Batch Requests](#batch-requests)
- [Errors Format](#errors-format)
- [CSRF Token Handling](#csrf-token-handling)
- [Client Library Differences](#client-library-differences)
- [Migration Checklist](#migration-checklist)

## Decision Matrix

| Scenario | Use v2 | Use v4 |
|----------|--------|--------|
| New CAP service | — | ✅ |
| New RAP service (ABAP ≥7.54) | — | ✅ |
| Fiori Elements on S/4HANA 2022+ | — | ✅ |
| Fiori Elements on S/4HANA 1909 | ✅ | — |
| Standard SAP OData API (many) | ✅ | — |
| UI5 app with growing tables | ✅ / ✅ | ✅ (better) |
| Analytical queries (groupby, aggregate) | ❌ | ✅ |
| Advanced filters (`in`, lambda) | ❌ | ✅ |
| Legacy Gateway service (SEGW) | ✅ | — |
| Full standardization (OASIS) | — | ✅ |

## URL Syntax Differences

```http
# Entity with single key
v2: GET /Products('HT-1001')
v4: GET /Products('HT-1001')                  # same short form
v4: GET /Products(ID='HT-1001')               # explicit

# Entity with composite key
v2: GET /Orders(OrderID=5,ItemID=1)
v4: GET /Orders(OrderID=5,ItemID=1)           # same

# Function import
v2: GET /GetMostRecent?count=5
v4: GET /getMostRecent(count=5)               # parentheses

# Property value
v2: GET /Products('HT-1001')/Name/$value
v4: GET /Products('HT-1001')/Name/$value      # same

# Count
v2: GET /Products/$count
v4: GET /Products/$count                      # same (also supports $count=true query option)

# Metadata
v2: GET /$metadata                            # EDMX 1.0
v4: GET /$metadata                            # EDMX 4.0 (different XML schema)
```

## Query Option Differences

| Option | v2 | v4 |
|--------|-----|-----|
| Count inline | `$inlinecount=allpages` | `$count=true` |
| Count only | `/$count` | `/$count` or `$count=true&$top=0` |
| Filter contains | `substringof('X', Name)` | `contains(Name, 'X')` |
| Filter any/all | ❌ | `Orders/any(o: o/Status eq 'Open')` |
| Filter `in` list | ❌ | `Category in ('A','B','C')` |
| Expand with sub-query | ❌ | `$expand=Orders($filter=...;$top=5)` |
| Apply (aggregations) | ❌ | `$apply=groupby(...)/aggregate(...)` |
| Search | ❌ | `$search=laptop` |
| Select | `$select=ID,Name` | `$select=ID,Name` (same) |
| Expand | `$expand=Supplier/Address` | `$expand=Supplier($expand=Address)` |

## Request/Response Format

### v2 JSON response
```json
{
  "d": {
    "__metadata": {
      "id": "Products('HT-1001')",
      "uri": "/sap/opu/odata/.../Products('HT-1001')",
      "type": "ZMY_SERVICE.Product",
      "etag": "W/\"...\""
    },
    "ID": "HT-1001",
    "Name": "Widget",
    "Price": "299.99",
    "Supplier": {
      "__deferred": { "uri": "Products('HT-1001')/Supplier" }
    }
  }
}
```

- Wrapped in `d`
- `__metadata`, `__deferred` wrapper objects
- Decimal values are **strings** to preserve precision
- Lists are in `d.results`, single entities in `d` itself

### v4 JSON response
```json
{
  "@odata.context": "$metadata#Products/$entity",
  "@odata.etag": "W/\"...\"",
  "ID": "HT-1001",
  "Name": "Widget",
  "Price": 299.99
}
```

- No `d` wrapper
- Metadata as top-level `@odata.*` annotations
- Numbers are **JSON numbers** (some clients still send decimals as strings for precision)
- Lists have `value` array: `{ "@odata.context": "...", "value": [...] }`

### v4 list response
```json
{
  "@odata.context": "$metadata#Products",
  "@odata.count": 1234,
  "value": [
    { "ID": "HT-1001", "Name": "Widget" },
    { "ID": "HT-1002", "Name": "Gadget" }
  ],
  "@odata.nextLink": "Products?$skip=20"
}
```

## Date/Time Handling

### v2
```http
# DateTime (Edm.DateTime)
$filter=CreatedAt eq datetime'2026-04-08T12:30:00'

# DateTimeOffset
$filter=CreatedAt eq datetimeoffset'2026-04-08T12:30:00Z'

# Time (Edm.Time)
$filter=StartTime eq time'PT12H30M'

# Response format (Unix epoch in milliseconds)
{ "CreatedAt": "/Date(1744116000000)/" }
```

### v4
```http
# Date (Edm.Date) — new in v4
$filter=OrderDate eq 2026-04-08

# DateTimeOffset (Edm.DateTimeOffset)
$filter=CreatedAt eq 2026-04-08T12:30:00Z

# TimeOfDay (Edm.TimeOfDay) — new in v4
$filter=StartTime eq 12:30:00

# Response format (ISO 8601 string)
{ "CreatedAt": "2026-04-08T12:30:00Z" }
```

**Migration pain:** v2 clients parsing `/Date(1234567890)/` need updates.

## Actions and Functions

### v2
All custom operations are "function imports". Use `GET` for side-effect-free, `POST` for side-effects.
```http
POST /ApproveProduct?ID='HT-1001'
GET /GetMostExpensive?count=5
```

### v4
Clear distinction:
- **Function** (no side effects): `GET` with parameters in URL
- **Action** (side effects): `POST` with parameters in body

```http
# Function
GET /getMostExpensive(count=5)

# Action
POST /approveProduct
Content-Type: application/json

{ "ID": "HT-1001" }
```

**Bound actions (v4 only):**
```http
POST /Products('HT-1001')/MyService.approve
```

## Batch Requests

### v2 — multipart/mixed
```http
POST /$batch
Content-Type: multipart/mixed; boundary=batch_123

--batch_123
Content-Type: application/http
Content-Transfer-Encoding: binary

GET /Products('HT-1001') HTTP/1.1
Host: server

--batch_123
Content-Type: multipart/mixed; boundary=changeset_456

--changeset_456
Content-Type: application/http

POST /Products HTTP/1.1
Content-Type: application/json

{ "ID": "HT-9999", "Name": "New" }

--changeset_456--
--batch_123--
```

### v4 — application/json (cleaner)
```http
POST /$batch
Content-Type: application/json

{
  "requests": [
    {
      "id": "1",
      "method": "GET",
      "url": "Products('HT-1001')"
    },
    {
      "id": "2",
      "atomicityGroup": "g1",
      "method": "POST",
      "url": "Products",
      "headers": { "Content-Type": "application/json" },
      "body": { "ID": "HT-9999", "Name": "New" }
    }
  ]
}
```

## Errors Format

### v2
```json
{
  "error": {
    "code": "ZMY_SERVICE/001",
    "message": { "lang": "en", "value": "Product not found" },
    "innererror": {
      "transactionid": "...",
      "timestamp": "...",
      "errordetails": []
    }
  }
}
```

### v4
```json
{
  "error": {
    "code": "001",
    "message": "Product not found",
    "target": "Products('HT-1001')",
    "details": [
      { "code": "002", "message": "Check the ID format" }
    ]
  }
}
```

## CSRF Token Handling

**Same mechanism in both versions:**
1. Send GET with `X-CSRF-Token: Fetch`
2. Server responds with `X-CSRF-Token: <value>` header
3. Include that value in subsequent write requests

No difference between v2 and v4 here.

## Client Library Differences

### UI5 ODataModel
```javascript
// v2
const oModel = new sap.ui.model.odata.v2.ODataModel("/sap/opu/odata/.../", {
  useBatch: true,
  defaultBindingMode: "TwoWay"
});

// v4
const oModel = new sap.ui.model.odata.v4.ODataModel({
  serviceUrl: "/odata/v4/products/",
  synchronizationMode: "None",
  operationMode: "Server",
  autoExpandSelect: true,        // v4 only — automatic $select/$expand
  earlyRequests: true            // v4 only — load metadata earlier
});
```

**Major v4 improvements:**
- `autoExpandSelect` — UI5 builds $select/$expand from bindings automatically
- Better async handling with promises
- Native support for server-side paging
- Cleaner typing (TypeScript definitions)

## Migration Checklist

When migrating a v2 service (or client) to v4:

- [ ] Check client compatibility — UI5 v4 model requires UI5 ≥ 1.108 for full features
- [ ] Update URL patterns — key syntax, metadata endpoint
- [ ] Replace `$inlinecount=allpages` with `$count=true`
- [ ] Replace `substringof` with `contains`
- [ ] Replace date literals — remove `datetime'...'` wrappers
- [ ] Update batch format if using custom clients — multipart → JSON
- [ ] Adjust JSON parsers — no more `d` wrapper, `results` becomes `value`
- [ ] Parse new `@odata.*` annotations
- [ ] Review Function Imports → migrate to v4 Actions/Functions with proper verbs
- [ ] Update error parsing — flat structure vs nested `message.value`
- [ ] Remove `/Date()/` parsers — use ISO 8601
- [ ] Re-test CSRF flows (same mechanism but headers may need tweaks)
- [ ] Update documentation and API catalogs
