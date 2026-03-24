---
name: sap-security-audit
description: Generate SAP security audit report. Scans for hardcoded credentials, missing auth checks, critical authorization patterns, and common security vulnerabilities in ABAP/CDS/UI5 code.
allowed-tools: Read Glob Grep Bash
---

# /sap-security-audit

Scan SAP project code for security vulnerabilities and generate audit report.

## Scan Categories

### CRITICAL — Hardcoded Credentials
```regex
password\s*=\s*['"][^'"]+['"]
secret\s*=\s*['"][^'"]+['"]
apikey\s*=\s*['"][^'"]+['"]
client_secret\s*=\s*['"][^'"]+['"]
Authorization.*Basic\s+[A-Za-z0-9+/=]{10,}
```

### CRITICAL — SQL Injection
```regex
CONCATENATE.*INTO.*WHERE           " Dynamic WHERE from string concatenation
|.*WHERE.*&&.*|                    " String template in WHERE clause
cl_abap_dyn_prg=>check_.*         " Dynamic SQL without sanitization check
ADBC.*execute.*                    " Native SQL without parameterization
```

### HIGH — Missing Authorization Checks
```regex
" ABAP: Methods performing CRUD without AUTHORITY-CHECK
INSERT\s+INTO\s+[^@]              " Direct DB insert without auth context
UPDATE\s+.*SET\s+                  " Direct DB update
DELETE\s+FROM\s+                   " Direct DB delete

" CDS: Missing access control
@AccessControl.authorizationCheck: #NOT_REQUIRED   " Explicitly disabled
" Missing @AccessControl annotation entirely
```

### HIGH — Sensitive Data Exposure
```regex
" Logging sensitive data
LOG.*password|LOG.*token|LOG.*secret
message.*password|message.*credential
cl_demo_output=>write.*password

" CDS: PII without annotation
" Fields like email, phone, salary without @Semantics.personalData
```

### MEDIUM — Security Best Practices
```regex
" HTTP without TLS
http://[^l]                        " Non-localhost HTTP URLs
" Disabled SSL validation
sslValidateCertificate.*false
verify.*false
" Overly broad authorization
SAP_ALL|S_DEVELOP.*ACTVT.*16      " Debug/replace authorization
```

## Output Format

```
╔══════════════════════════════════════════════╗
║  SAP Security Audit Report                   ║
║  Generated: {{DATE}}                         ║
╠══════════════════════════════════════════════╣
║  Files scanned:  {{COUNT}}                   ║
║  Critical:       {{COUNT}} 🔴                ║
║  High:           {{COUNT}} 🟠                ║
║  Medium:         {{COUNT}} 🟡                ║
╚══════════════════════════════════════════════╝

🔴 CRITICAL: Hardcoded Credentials
  📍 srv/config.js:15 — password = "Admin123!"
     → Move to environment variable or BTP credential store
     → Reference: SAP BTP Credential Store service

🔴 CRITICAL: SQL Injection Risk
  📍 src/zcl_search.abap:42 — Dynamic WHERE from user input
     → Use parameterized queries or cl_abap_dyn_prg=>quote()

🟠 HIGH: Missing Authorization
  📍 src/zi_salesorder.asddls — No @AccessControl annotation
     → Add access control with PFCG aspect mapping

🟡 MEDIUM: HTTP without TLS
  📍 webapp/manifest.json:28 — http://api.example.com
     → Change to https://
```

## Execution Steps

1. Glob all source files: `**/*.{abap,cds,asddls,js,ts,json,xml,yaml,yml,properties}`
2. Run each regex pattern category against matched files
3. Classify and deduplicate findings
4. Generate report with file:line references and remediation steps
5. Print summary statistics
