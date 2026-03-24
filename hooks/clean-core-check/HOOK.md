---
name: clean-core-check
description: Clean Core compliance pre-commit hook. Blocks commits containing non-released API usage, hardcoded credentials, or critical Clean Core violations.
trigger: pre-commit
file-patterns: ["*.abap", "*.cds", "*.asddls"]
---

# Clean Core Pre-Commit Hook

Blocks commits that introduce Clean Core violations in ABAP/CDS code.

## Blocking Rules (Commit Rejected)

### Non-Released API Patterns
```regex
CALL FUNCTION\s+'(?!Z|Y|/)[A-Z_]+'     " Non-custom function module call
SELECT\s+.*\s+FROM\s+(?!z|y)[a-z]{2,5}\b  " Direct SAP table access (2-5 char tables)
```

### Hardcoded Credentials
```regex
password\s*=\s*['"][^'"]{3,}['"]
client_secret\s*=\s*['"][^'"]+['"]
SharedSecret>[^<]{5,}</SharedSecret
```

### Critical Security
```regex
AUTHORITY-CHECK\s+.*DUMMY     " Dummy auth check (bypasses security)
SAP_ALL                        " Reference to SAP_ALL profile
```

## Warning Rules (Commit Allowed, Warning Shown)

```regex
SELECT\s+\*\s+FROM            " SELECT * (performance)
WRITE[\s:]                     " Classic list output
FORM\s+\w+                     " FORM/ENDFORM (obsolete)
INCLUDE\s+[^.]                 " INCLUDE statement
```

## Output on Violation

```
🚫 COMMIT BLOCKED — Clean Core Violation

  BLOCKER: src/zcl_processor.abap:42
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    → Use released alternative or create Tier 2 wrapper
    → Reference: Cloudification Repository (api.sap.com)

  BLOCKER: src/z_config.abap:15
    password = "secret123"
    → Move to BTP Credential Store or secure parameter

Fix these issues and commit again.
Use --no-verify to bypass (NOT recommended).
```

## Bypass
```bash
# Emergency bypass (requires justification in commit message)
git commit --no-verify -m "EMERGENCY: [justification] ..."
```

Hook bypass should be documented and reviewed in code review process.
