---
name: sap-hana-cloud
description: >
  SAP HANA Cloud database development and administration skill. Use when writing SQLScript
  procedures, creating calculation views, managing HDI containers, optimizing HANA SQL,
  using spatial/graph/JSON engines, or configuring data tiering (NSE). If the user mentions
  HANA Cloud, SQLScript, calculation view, HDI container, or HANA performance tuning,
  use this skill. Covers QRC 2025+.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP HANA Cloud Database Development

## Related Skills
- `sap-rap-comprehensive` — CDS views consumed by HANA models
- `sap-s4hana-extensibility` — Custom CDS/HANA artifacts in S/4HANA extensions
- `sap-business-ai-joule` — Vector engine for AI/RAG scenarios
- `sap-hana-tools` — hdbsql CLI, HDI management, and HANA client tooling
- `sap-cap-advanced` — CAP with HANA Cloud native artifacts

## Quick Start

**Choose your development approach:**

| Scenario | Tool | Artifact |
|----------|------|----------|
| BTP CAP application | SAP Business Application Studio | `.hdbcds`, `.hdbprocedure` in `db/src/` |
| Native HANA development | SAP HANA Database Explorer | HDI container objects |
| Data warehouse / analytics | SAP HANA Cloud Central | Calculation views, flowgraphs |
| Data tiering | HANA Cloud Central | Data Lake / Native Storage Extension |

**Minimal HDI procedure:**

```sql
PROCEDURE "mySchema.myProc" (
  IN iv_customer_id NVARCHAR(10),
  OUT et_orders TABLE (order_id NVARCHAR(10), amount DECIMAL(15,2))
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
READS SQL DATA
AS
BEGIN
  et_orders = SELECT order_id, amount
              FROM "ORDERS"
              WHERE customer_id = :iv_customer_id;
END;
```

## Core Concepts

### HDI Containers (HANA Deployment Infrastructure)
- **Schema-less development**: Objects reference each other by name, HDI assigns runtime schema
- **Build plugins**: Each artifact type (`.hdbcds`, `.hdbprocedure`, `.hdbtable`) has a build plugin
- **Container groups**: Isolate tenants; cross-container access via synonyms + `.hdbgrants`
- **Undeploy whitelist**: `undeploy.json` controls what can be removed on redeploy

### Multi-Model Engines
| Engine | Use Case | Key Type |
|--------|----------|----------|
| Relational | Standard OLTP/OLAP | TABLE, VIEW |
| Document Store | Schema-flexible JSON | COLLECTION |
| Graph | Network/relationship analysis | GRAPH WORKSPACE |
| Spatial | Geospatial queries | ST_GEOMETRY, ST_POINT |
| Vector | AI embeddings / similarity search | REAL_VECTOR |

### Data Tiering
1. **Hot store**: In-memory, fastest, most expensive
2. **HANA Native Storage Extension (NSE)**: Disk-based, buffer cache, warm data
3. **HANA Cloud Data Lake (HDLR)**: Relational cold storage, SQL access
4. **Data Lake Files**: Object store for unstructured/semi-structured data

## Common Patterns

### Pattern 1: Table with NSE Page Loadable Columns

```sql
-- .hdbtable
COLUMN TABLE "SALES_HISTORY" (
  "ID"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CUSTOMER_ID" NVARCHAR(10) NOT NULL,
  "ORDER_DATE"  DATE NOT NULL,
  "AMOUNT"      DECIMAL(15,2),
  "DETAILS"     NCLOB
) WITH PARAMETERS ('PARTITION_SPEC' = 'RANGE (ORDER_DATE)
  (PARTITION VALUE <= ''2023-12-31'' PAGE LOADABLE,
   PARTITION OTHERS COLUMN LOADABLE)');
```

### Pattern 2: SQLScript with Error Handling

```sql
PROCEDURE "processOrders" (
  IN iv_date DATE,
  OUT ov_count INTEGER,
  OUT ov_status NVARCHAR(20)
)
LANGUAGE SQLSCRIPT
SQL SECURITY INVOKER
AS
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ov_status = 'ERROR';
    ov_count = 0;
  END;

  DECLARE lv_count INTEGER;

  SELECT COUNT(*) INTO lv_count
    FROM "ORDERS"
    WHERE order_date = :iv_date
      AND status = 'PENDING';

  UPDATE "ORDERS"
    SET status = 'PROCESSED', processed_at = CURRENT_TIMESTAMP
    WHERE order_date = :iv_date
      AND status = 'PENDING';

  ov_count = :lv_count;
  ov_status = 'SUCCESS';
END;
```

### Pattern 3: Graph Workspace

```sql
-- .hdbgraphworkspace
GRAPH WORKSPACE "EMPLOYEE_ORG"
  EDGE TABLE "ORG_EDGES"
    SOURCE COLUMN "MANAGER_ID"
    TARGET COLUMN "EMPLOYEE_ID"
    KEY COLUMN "EDGE_ID"
  VERTEX TABLE "EMPLOYEES"
    KEY COLUMN "EMPLOYEE_ID";
```

```sql
-- Query: find all reports (direct + indirect) for a manager
SELECT * FROM "EMPLOYEES" e
WHERE e."EMPLOYEE_ID" IN (
  SELECT "EMPLOYEE_ID" FROM GRAPH_TABLE("EMPLOYEE_ORG"
    MATCH (mgr)-[EDGE * 1..10]->(emp)
    WHERE mgr."EMPLOYEE_ID" = 'MGR001'
    COLUMNS (emp."EMPLOYEE_ID")
  )
);
```

### Pattern 4: JSON Document Store

```sql
CREATE COLLECTION "DEVICE_EVENTS";

INSERT INTO "DEVICE_EVENTS" VALUES('{"deviceId":"D001","ts":"2026-01-15T10:30:00Z","temp":22.5,"status":"OK"}');

-- Query nested JSON
SELECT "deviceId", "ts", "temp"
  FROM "DEVICE_EVENTS"
  WHERE "temp" > 30.0
  ORDER BY "ts" DESC;
```

### Pattern 5: Vector Engine for Embeddings

```sql
CREATE TABLE "KNOWLEDGE_BASE" (
  "ID"        BIGINT PRIMARY KEY,
  "CONTENT"   NCLOB,
  "EMBEDDING" REAL_VECTOR(1536)
);

-- Similarity search (cosine)
SELECT TOP 5 "ID", "CONTENT",
       COSINE_SIMILARITY("EMBEDDING", TO_REAL_VECTOR(:iv_query_embedding)) AS score
  FROM "KNOWLEDGE_BASE"
  ORDER BY score DESC;
```

### Pattern 6: Cross-Container Access

```json
// .hdbgrants file
{
  "external_service": {
    "object_owner": {
      "schema_privileges": [
        { "schema_reference": "external_schema", "privileges": ["SELECT"] }
      ]
    },
    "application_user": {
      "schema_privileges": [
        { "schema_reference": "external_schema", "privileges": ["SELECT"] }
      ]
    }
  }
}
```

```json
// .hdbsynonym file
{
  "EXT_CUSTOMERS": {
    "target": {
      "object": "CUSTOMERS",
      "schema.configure": "external_schema"
    }
  }
}
```

### Pattern 7: Calculation View (Column Engine)

Calculation views are typically created in SAP Business Application Studio graphical editor.
Key design principles:
- Push filters as low as possible in the view stack
- Use star joins for dimension/fact models
- Prefer calculated columns over calculated attributes for complex logic
- Set cardinality on joins to enable query optimization
- Use input parameters for mandatory runtime filters

## Error Catalog

| Error Code | Message | Root Cause | Fix |
|------------|---------|------------|-----|
| `ERR_SQL_INV_TABLE` | Invalid table name | Object not in HDI container / wrong schema | Check synonym config or `.hdbgrants` |
| `258` | Insufficient privilege | Missing SELECT/EXECUTE grant | Update `.hdbgrants`, redeploy container |
| `429` | Memory allocation failed | Query exceeds memory limit | Add filters, use NSE, check `statement_memory_limit` |
| `131` | Transaction rolled back: lock wait timeout | Long-running concurrent updates | Reduce transaction scope, check FOR UPDATE usage |
| `2048` | Column store error | Corrupt delta merge or index | Run `ALTER TABLE ... MERGE DELTA OF ...` |
| Build error | `Plugin not found` | Missing HDI build plugin in `.hdiconfig` | Add plugin mapping for artifact suffix |

## Performance Tips

1. **Partition large tables** — Hash for OLTP, range on date for time-series, round-robin for parallel scans
2. **Use NSE for warm data** — `ALTER TABLE ... PAGE LOADABLE` for columns accessed < daily
3. **Avoid SELECT *** — HANA is columnar; fewer columns = faster scans
4. **Use HINTS sparingly** — `WITH HINT(NO_CS_JOIN)` only after plan analysis
5. **Monitor with**: `M_SQL_PLAN_CACHE`, `M_EXPENSIVE_STATEMENTS`, `M_SERVICE_MEMORY`
6. **Delta merge**: Large delta stores slow reads; schedule merges for bulk-load tables
7. **Parameterize queries** — Prepared statements reuse execution plans
8. **Data Lake for cold data** — Move data older than N years to HDLR, keep hot queries fast
9. **Calculation view pruning** — Enable `ANALYTIC_VIEW_PARAMETERS` for optimizer pruning

## Gotchas

- **HDI deploy order**: Dependencies must be resolved; circular references between `.hdbsynonym` and `.hdbview` will fail — use `.hdbsynonymconfig` for external schemas
- **CURRENT_SCHEMA vs container schema**: In HDI, never hard-code schema names; use synonyms
- **Session variables**: `SET 'variable' = 'value'` does NOT persist across connections in cloud
- **Data Lake SQL subset**: HDLR supports SQL but not full SQLScript — no procedures in Data Lake
- **Memory limits**: HANA Cloud has per-statement memory limits (default 8 GB) — monitor with `M_EXPENSIVE_STATEMENTS`

## MCP Server Integration

```json
{
  "mcpServers": {
    "hana-mcp": {
      "command": "npx", "args": ["-y", "hana-mcp-server"],
      "env": { "HANA_HOST": "your-instance.hana.trial-us10.hanacloud.ondemand.com",
               "HANA_PORT": "443", "HANA_USER": "YOUR_USER", "HANA_PASSWORD": "YOUR_PASSWORD" }
    }
  }
}
```

- **HANA MCP**: Direct HANA Cloud database access for queries and administration
