---
name: sap-hana-tools
description: >
  SAP HANA developer tooling and CLI skill. Use when working with hdbsql CLI, managing HDI
  containers, using HANA Database Explorer, or automating HANA operations. If the user
  mentions hdbsql, HDI container management, HANA Cloud Central, or HANA client tools,
  use this skill. Extends sap-hana-cloud with operational tooling focus.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP HANA Developer Tools & CLI

## Related Skills
- `sap-hana-cloud` — HANA Cloud database development (SQL, HDI, multi-model)
- `sap-devops-cicd` — HANA artifact deployment in CI/CD pipelines
- `sap-cap-advanced` — CAP projects with HANA Cloud persistence

## Quick Start

**Key tools:**

| Tool | Purpose | Install |
|------|---------|---------|
| `hdbsql` | Interactive SQL client | SAP HANA Client package |
| `hdbuserstore` | Secure credential store | SAP HANA Client package |
| `@sap/hdi-deploy` | HDI container deployer | `npm install @sap/hdi-deploy` |
| HANA Database Explorer | Web-based SQL editor | BTP cockpit → HANA Cloud |
| HANA Cloud Central | Instance management | BTP cockpit |
| `@sap/hana-client` | Node.js HANA driver | `npm install @sap/hana-client` |

**Connect with hdbsql:**

```bash
# Store credentials securely
hdbuserstore SET HANACLOUD <host>:443 <user> <password>

# Connect and run query
hdbsql -U HANACLOUD "SELECT * FROM M_DATABASE"

# Connect directly
hdbsql -n <host>:443 -u <user> -p <password> -encrypt
```

## Core Concepts

### HDI Container Lifecycle (CLI)
```bash
# HDI deploy from command line (CI/CD)
npx @sap/hdi-deploy \
  --service-replacements '{"hdi-container":"my-hdi-service-key"}' \
  --deploy '["src/**"]' \
  --undeploy '["src/old_table.hdbtable"]'

# Environment variables for HDI deploy
export HDI_DEPLOY_OPTIONS='{"auto_undeploy":false,"treat_warnings_as_errors":true}'
```

### Connection Methods
| Method | Use Case | Security |
|--------|----------|----------|
| `hdbuserstore` | Persistent, scripted access | Encrypted local store |
| Direct params | One-off queries | Password on command line (avoid in prod) |
| JWT token | BTP app auth | Short-lived, OAuth 2.0 |
| X.509 certificate | Service-to-service | Mutual TLS |
| Service key (JSON) | BTP service binding | From BTP cockpit |

### hdbsql Output Formats
```bash
# CSV output (for data export)
hdbsql -U HANACLOUD -o output.csv -c "," -a "SELECT * FROM MY_TABLE"

# JSON output (pipe to jq)
hdbsql -U HANACLOUD -j "SELECT TOP 10 * FROM M_SQL_PLAN_CACHE ORDER BY total_execution_time DESC"

# Aligned column output (human-readable)
hdbsql -U HANACLOUD -A "SELECT * FROM M_SERVICE_MEMORY"
```

## Common Patterns

### Pattern 1: HANA Health Check Script

```bash
#!/bin/bash
# hana_health_check.sh — Daily HANA Cloud health report

STORE_KEY="HANACLOUD"

echo "=== HANA Cloud Health Check $(date) ==="

echo -e "\n--- Database Info ---"
hdbsql -U $STORE_KEY -j "SELECT DATABASE_NAME, VERSION, USAGE FROM M_DATABASE"

echo -e "\n--- Memory Usage ---"
hdbsql -U $STORE_KEY -A "
  SELECT HOST,
         ROUND(USED_PHYSICAL_MEMORY/1024/1024/1024, 2) AS USED_GB,
         ROUND(FREE_PHYSICAL_MEMORY/1024/1024/1024, 2) AS FREE_GB,
         ROUND(USED_PHYSICAL_MEMORY * 100.0 / (USED_PHYSICAL_MEMORY + FREE_PHYSICAL_MEMORY), 1) AS USED_PCT
  FROM M_HOST_RESOURCE_UTILIZATION"

echo -e "\n--- Top 5 Expensive Queries (Last 24h) ---"
hdbsql -U $STORE_KEY -A "
  SELECT TOP 5
    SUBSTRING(STATEMENT_STRING, 1, 80) AS QUERY,
    ROUND(DURATION_MICROSEC/1000000, 2) AS DURATION_SEC,
    RECORDS AS ROWS_AFFECTED
  FROM M_EXPENSIVE_STATEMENTS
  WHERE START_TIME > ADD_SECONDS(CURRENT_TIMESTAMP, -86400)
  ORDER BY DURATION_MICROSEC DESC"

echo -e "\n--- Active Connections ---"
hdbsql -U $STORE_KEY -A "
  SELECT CONNECTION_STATUS, COUNT(*) AS CNT
  FROM M_CONNECTIONS
  GROUP BY CONNECTION_STATUS"

echo -e "\n--- Table Growth (Top 10 by size) ---"
hdbsql -U $STORE_KEY -A "
  SELECT TOP 10
    SCHEMA_NAME, TABLE_NAME,
    ROUND(TABLE_SIZE/1024/1024, 2) AS SIZE_MB,
    RECORD_COUNT
  FROM M_CS_TABLES
  ORDER BY TABLE_SIZE DESC"
```

### Pattern 2: Node.js HANA Client

```javascript
const hana = require('@sap/hana-client');

class HANAConnection {
  constructor(serviceKey) {
    this.connParams = {
      host: serviceKey.host,
      port: serviceKey.port,
      uid: serviceKey.user,
      pwd: serviceKey.password,
      encrypt: true,
      sslValidateCertificate: true
    };
  }

  async query(sql, params = []) {
    const conn = hana.createConnection();
    try {
      await new Promise((resolve, reject) =>
        conn.connect(this.connParams, (err) => err ? reject(err) : resolve())
      );
      return await new Promise((resolve, reject) =>
        conn.exec(sql, params, (err, result) => err ? reject(err) : resolve(result))
      );
    } finally {
      conn.disconnect();
    }
  }

  async streamLargeResult(sql, params, onRow) {
    const conn = hana.createConnection();
    await new Promise((resolve, reject) =>
      conn.connect(this.connParams, (err) => err ? reject(err) : resolve())
    );
    const stmt = conn.prepare(sql);
    const rs = stmt.execQuery(params);
    while (rs.next()) {
      await onRow(rs.getValues());
    }
    rs.close();
    stmt.drop();
    conn.disconnect();
  }
}

// Usage
const db = new HANAConnection(JSON.parse(process.env.HANA_SERVICE_KEY));
const results = await db.query(
  'SELECT * FROM ORDERS WHERE CUSTOMER_ID = ? AND ORDER_DATE > ?',
  ['CUST001', '2026-01-01']
);
```

### Pattern 3: HDI Container Management Script

```bash
#!/bin/bash
# Manage HDI containers for multi-tenant scenario

SERVICE_INSTANCE="my-hdi-shared"

# List all HDI containers
cf service-keys $SERVICE_INSTANCE | grep -E "^name"

# Create tenant-specific container
create_tenant_container() {
  local TENANT_ID=$1
  local CONTAINER_NAME="hdi-${TENANT_ID}"

  cf create-service-key $SERVICE_INSTANCE $CONTAINER_NAME \
    -c "{\"permissions\":\"development\"}"

  # Get connection details
  cf service-key $SERVICE_INSTANCE $CONTAINER_NAME | tail -n +2 > /tmp/${CONTAINER_NAME}.json

  # Deploy schema to new container
  HDI_SERVICE_KEY=$(cat /tmp/${CONTAINER_NAME}.json)
  npx @sap/hdi-deploy --service-replacements "[{\"key\":\"hdi-container\",\"service\":\"$HDI_SERVICE_KEY\"}]"
}

# Delete tenant container
delete_tenant_container() {
  local TENANT_ID=$1
  cf delete-service-key $SERVICE_INSTANCE "hdi-${TENANT_ID}" -f
}
```

### Pattern 4: Performance Analysis Queries

```sql
-- Find slow queries in plan cache
SELECT TOP 20
  STATEMENT_HASH,
  EXECUTION_COUNT,
  ROUND(TOTAL_EXECUTION_TIME/1000000, 2) AS TOTAL_SEC,
  ROUND(AVG_EXECUTION_TIME/1000000, 2) AS AVG_SEC,
  ROUND(MAX_EXECUTION_TIME/1000000, 2) AS MAX_SEC,
  TOTAL_LOCK_WAIT_COUNT,
  SUBSTR(STATEMENT_STRING, 1, 100) AS QUERY_PREVIEW
FROM M_SQL_PLAN_CACHE
WHERE EXECUTION_COUNT > 10
ORDER BY AVG_EXECUTION_TIME DESC;

-- Table column memory consumption
SELECT SCHEMA_NAME, TABLE_NAME, COLUMN_NAME,
       ROUND(MEMORY_SIZE_IN_TOTAL/1024/1024, 2) AS TOTAL_MB,
       ROUND(PERSISTENT_MEMORY_SIZE_IN_TOTAL/1024/1024, 2) AS DISK_MB,
       LOADED AS IS_LOADED
FROM M_CS_COLUMNS
WHERE SCHEMA_NAME = 'MY_SCHEMA'
ORDER BY MEMORY_SIZE_IN_TOTAL DESC;

-- Index advisor suggestions
SELECT * FROM M_CS_INDEXES_ADVISOR
WHERE SCHEMA_NAME = 'MY_SCHEMA'
ORDER BY ESTIMATED_BENEFIT DESC;

-- Check delta merge status
SELECT SCHEMA_NAME, TABLE_NAME, PART_ID,
       RAW_RECORD_COUNT_IN_DELTA AS DELTA_ROWS,
       RAW_RECORD_COUNT_IN_MAIN AS MAIN_ROWS,
       ROUND(RAW_RECORD_COUNT_IN_DELTA * 100.0 /
         NULLIF(RAW_RECORD_COUNT_IN_MAIN + RAW_RECORD_COUNT_IN_DELTA, 0), 1) AS DELTA_PCT
FROM M_CS_TABLES
WHERE RAW_RECORD_COUNT_IN_DELTA > 100000
ORDER BY RAW_RECORD_COUNT_IN_DELTA DESC;
```

### Pattern 5: Python HANA Client (hdbcli)

```python
from hdbcli import dbapi
import json

def connect_from_service_key(key_path):
    """Connect using BTP service key JSON."""
    with open(key_path) as f:
        key = json.load(f)
    return dbapi.connect(
        address=key["host"],
        port=key["port"],
        user=key["user"],
        password=key["password"],
        encrypt=True
    )

def export_to_csv(conn, sql, output_path):
    """Export query results to CSV."""
    import csv
    cursor = conn.cursor()
    cursor.execute(sql)
    columns = [desc[0] for desc in cursor.description]
    with open(output_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(columns)
        while True:
            rows = cursor.fetchmany(10000)
            if not rows:
                break
            writer.writerows(rows)
    cursor.close()

def bulk_insert(conn, table_name, data, batch_size=5000):
    """Efficient bulk insert with parameterized batches."""
    if not data:
        return
    columns = list(data[0].keys())
    placeholders = ','.join(['?' for _ in columns])
    sql = f"INSERT INTO {table_name} ({','.join(columns)}) VALUES ({placeholders})"

    cursor = conn.cursor()
    for i in range(0, len(data), batch_size):
        batch = data[i:i+batch_size]
        params = [tuple(row[c] for c in columns) for row in batch]
        cursor.executemany(sql, params)
    conn.commit()
    cursor.close()
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `hdbsql: -10709` | Connection failed | Wrong host/port or network issue | Check host:443 (HANA Cloud always uses 443) |
| `hdbsql: -10104` | Invalid credentials | Wrong user/password | Reset password; check hdbuserstore entry |
| `hdbsql: -10` | Encryption required | Missing `-encrypt` flag | Add `-encrypt` or `encrypt=true` |
| `hdi-deploy: 403` | Insufficient privilege | Missing HDI admin role | Grant HDI container admin to technical user |
| `hdi-deploy: Build failed` | Artifact compilation error | Invalid HDB artifact syntax | Check `.hdbcds`/`.hdbprocedure` syntax |
| `npm: @sap/hana-client` | Install failed (native module) | Missing C++ build tools | Install `node-gyp` prereqs; use prebuild binary |
| `SQLCODE -131` | Transaction rolled back | Lock timeout during bulk insert | Reduce batch size; check for concurrent access |
| `SQLCODE -10001` | SQL syntax error | HANA SQL ≠ ANSI SQL | Check HANA-specific syntax (e.g., `TOP N` not `LIMIT N`) |

## Performance Tips

1. **Use hdbuserstore** — Avoid passwords in scripts; `hdbuserstore` is encrypted and reusable
2. **Batch size for hdbsql** — Use `-B` (batch mode) for non-interactive execution in CI/CD
3. **Parameterized queries** — Always use `?` placeholders; prevents SQL injection and enables plan reuse
4. **Connection pooling** — In Node.js/Python apps, reuse connections; don't connect per query
5. **hdbsql -j for JSON** — JSON output is parse-friendly for automation scripts
6. **HDI deploy incremental** — Only deploy changed files; use `--deploy` with specific file paths
7. **Export large datasets** — Use `hdbsql -o` with CSV format for data export instead of SELECT in app code

## Gotchas

- **HANA Cloud port**: Always 443 (not 30015/30013 like on-premise)
- **hdbsql LIMIT**: HANA uses `SELECT TOP N` not `LIMIT N` (though recent versions support both)
- **Node.js driver versions**: `@sap/hana-client` (native, faster) vs `hdb` (pure JS, slower but no native deps)
- **hdbuserstore scope**: Keys are per-OS-user; CI/CD needs its own userstore setup
- **SSL certificates**: HANA Cloud uses DigiCert root CA; ensure it's in your trust store
- **Time zone**: HANA Cloud always runs in UTC; convert in queries with `UTCTOLOCAL()`
