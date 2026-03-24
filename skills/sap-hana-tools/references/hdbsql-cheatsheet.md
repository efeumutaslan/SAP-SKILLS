# hdbsql CLI — Quick Reference

## Connection

```bash
# Basic connection
hdbsql -n <host>:443 -u <user> -p <password> -d <database>

# With encryption (HANA Cloud)
hdbsql -n <host>:443 -u <user> -p <password> -encrypt

# Using hdbuserstore key
hdbuserstore SET mykey <host>:443 <user> <password>
hdbsql -U mykey

# Connect to specific tenant DB
hdbsql -n <host>:443 -d <tenant_db> -u <user> -p <password>
```

## Output Formatting

```bash
# CSV output
hdbsql -U mykey -o output.csv -F "," -a "SELECT * FROM MY_TABLE"

# JSON-like output
hdbsql -U mykey -resultencoding utf8 -j "SELECT * FROM MY_TABLE"

# Column-aligned
hdbsql -U mykey -C "SELECT * FROM MY_TABLE"

# Suppress headers
hdbsql -U mykey -a -x "SELECT COUNT(*) FROM MY_TABLE"

# Execute from file
hdbsql -U mykey -I script.sql

# Multiple statements
hdbsql -U mykey -m <<'EOF'
SELECT COUNT(*) FROM TABLE1;
SELECT COUNT(*) FROM TABLE2;
EOF
```

## HDI Container Management

```bash
# List HDI containers
hdbsql -U mykey "SELECT * FROM _SYS_DI.M_ALL_CONTAINERS"

# Container status
hdbsql -U mykey "SELECT CONTAINER_NAME, STATUS FROM _SYS_DI.M_ALL_CONTAINERS WHERE CONTAINER_NAME LIKE '%myapp%'"

# Grant access to HDI container schema
hdbsql -U mykey "CALL _SYS_DI.GRANT_CONTAINER_SCHEMA_PRIVILEGES('my-container', _SYS_DI.T_SCHEMA_PRIVILEGES, _SYS_DI.T_NO_PARAMETERS, ?, ?, ?)"
```

## Performance Analysis

```bash
# Top memory consumers
hdbsql -U mykey "SELECT TOP 20 SCHEMA_NAME, TABLE_NAME, ROUND(MEMORY_SIZE_IN_TOTAL/1024/1024,2) AS MB FROM M_CS_TABLES ORDER BY MEMORY_SIZE_IN_TOTAL DESC"

# Active queries > 5 seconds
hdbsql -U mykey "SELECT CONNECTION_ID, ROUND(DURATION_MICROSEC/1000000,2) AS sec, SUBSTR(STATEMENT_STRING,1,100) FROM M_ACTIVE_STATEMENTS WHERE DURATION_MICROSEC > 5000000"

# Plan cache analysis
hdbsql -U mykey "SELECT STATEMENT_HASH, EXECUTION_COUNT, ROUND(AVG_EXECUTION_TIME/1000,2) AS avg_ms, TOTAL_EXECUTION_TIME FROM M_SQL_PLAN_CACHE ORDER BY TOTAL_EXECUTION_TIME DESC FETCH FIRST 20 ROWS ONLY"

# Table partitions
hdbsql -U mykey "SELECT TABLE_NAME, PART_ID, RECORD_COUNT, ROUND(DISK_SIZE/1024/1024,2) AS disk_mb FROM M_TABLE_PARTITIONS WHERE SCHEMA_NAME = 'MY_SCHEMA'"
```

## Administration

```bash
# Database overview
hdbsql -U mykey "SELECT * FROM M_DATABASE"

# Memory overview
hdbsql -U mykey "SELECT ROUND(USED_PHYSICAL_MEMORY/1024/1024/1024,2) AS used_gb, ROUND(FREE_PHYSICAL_MEMORY/1024/1024/1024,2) AS free_gb FROM M_HOST_RESOURCE_UTILIZATION"

# Kill a long-running statement
hdbsql -U mykey "ALTER SYSTEM CANCEL SESSION '<connection_id>'"

# Export table to CSV
hdbsql -U mykey "EXPORT MY_SCHEMA.MY_TABLE AS CSV INTO '/tmp/export/' WITH THREADS 4"

# Import CSV
hdbsql -U mykey "IMPORT MY_SCHEMA.MY_TABLE AS CSV FROM '/tmp/import/' WITH THREADS 4 ERROR LOG '/tmp/import_errors.log'"
```

## Node.js Client (@sap/hana-client)

```javascript
const hana = require('@sap/hana-client');

const conn = hana.createConnection();
conn.connect({
  host: process.env.HANA_HOST,
  port: 443,
  uid: process.env.HANA_USER,
  pwd: process.env.HANA_PASSWORD,
  encrypt: true,
  sslValidateCertificate: true
});

// Query
const results = conn.exec('SELECT TOP 10 * FROM MY_TABLE WHERE STATUS = ?', ['active']);
console.log(results);

// Prepared statement
const stmt = conn.prepare('INSERT INTO MY_TABLE (ID, NAME) VALUES (?, ?)');
stmt.exec([1, 'Test']);
stmt.drop();

conn.disconnect();
```

## Python Client (hdbcli)

```python
from hdbcli import dbapi

conn = dbapi.connect(
    address="<host>",
    port=443,
    user="<user>",
    password="<password>",
    encrypt=True
)

cursor = conn.cursor()
cursor.execute("SELECT TOP 10 * FROM MY_TABLE")
rows = cursor.fetchall()
for row in rows:
    print(row)

cursor.close()
conn.close()
```
