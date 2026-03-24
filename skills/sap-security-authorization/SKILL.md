---
name: sap-security-authorization
description: |
  SAP security, authorization, and compliance skill. Use when: designing PFCG roles,
  working with authorization objects, analyzing SU53 errors, checking SoD conflicts,
  implementing SOX/GDPR/ISO 27001 compliance, configuring SAP Cloud Identity Services
  (IAS/IPS), setting up principal propagation, managing BTP security (XSUAA),
  auditing user access, reviewing SAP_ALL assignments, detecting dormant users,
  configuring Security Audit Log, or implementing data protection (ILM).
  Covers on-premise, S/4HANA Cloud, and BTP.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP Security & Authorization

## Related Skills
- `sap-s4hana-extensibility` — Extension authorization patterns
- `sap-build-process-automation` — Approval workflow design
- `sap-rap-comprehensive` — RAP authorization (global/instance)

## Quick Start

**Authorization error? Start here:**
1. Run **SU53** (or for another user: SU53 → Other User)
2. Check which authorization object failed and what values were needed
3. If SU53 is not enough, use **STAUTHTRACE** for full trace (captures all checks, not just failures)

**Design a role:**
1. **SU24** — Check authorization defaults for the transaction
2. **PFCG** — Create single role, add transactions to menu
3. Generate profile → Adjust authorization values → Save
4. Create **derived roles** for org-level variations (company code, plant)
5. Assign role to user via **SU01**

**BTP authorization:**
1. Define **scopes** and **role-templates** in `xs-security.json`
2. Create **role collections** in BTP cockpit
3. Assign role collections to users/groups

## Core Concepts

### On-Premise Authorization Hierarchy

```
User (SU01)
  └── Role (PFCG)
        └── Profile (auto-generated)
              └── Authorization Object
                    └── Field = Value
```

### Role Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Single** | Contains tcodes, auth objects, field values | Job-based access |
| **Composite** | Groups single roles; no own authorizations | Combining functions |
| **Derived (Child)** | Inherits from master; only org-level values differ | Multi-org access |

**Naming convention:** `Z_<MODULE>_<FUNCTION>_<TYPE>` (e.g., `Z_FI_AP_CLERK_S`, `_C` for composite, `_D` for derived)

### Critical Authorization Objects

| Object | Fields | Controls |
|--------|--------|----------|
| **S_TCODE** | TCD | Transaction access |
| **S_RFC** | RFC_TYPE, RFC_NAME, ACTVT | RFC/function module execution |
| **S_SERVICE** | SRV_NAME, SRV_TYPE | Fiori/OData service access |
| **S_TABU_DIS** | DICBERCLS, ACTVT | Table access by auth group |
| **S_TABU_NAM** | TABLE | Table access by name |
| **S_DEVELOP** | DEVCLASS, OBJTYPE, OBJNAME, ACTVT | ABAP development |
| **S_USER_GRP** | CLASS, ACTVT | User master maintenance |
| **S_USER_AGR** | ACT_GROUP, ACTVT | Role assignment |
| **S_PROGRAM** | P_ACTION, P_GROUP | Program execution |

### BTP Authorization Model (XSUAA)

```
User/Group
  └── Role Collection
        └── Role
              └── Role Template
                    └── Scope ($XSAPPNAME.Read, $XSAPPNAME.Admin)
```

**xs-security.json example:**
```json
{
  "xsappname": "myapp",
  "tenant-mode": "dedicated",
  "scopes": [
    { "name": "$XSAPPNAME.Read", "description": "Read access" },
    { "name": "$XSAPPNAME.Admin", "description": "Admin access" }
  ],
  "role-templates": [
    { "name": "Viewer", "scope-references": ["$XSAPPNAME.Read"] },
    { "name": "Administrator", "scope-references": ["$XSAPPNAME.Read", "$XSAPPNAME.Admin"] }
  ]
}
```

### S/4HANA Cloud Authorization

On-premise PFCG roles are replaced by:
- **Business Catalogs** — Grouped app authorizations
- **Business Roles** — Assign catalogs + restriction types to users
- **Restriction Types** — Read/Write/Value Help access control (replaces org-level values)
- **Maintain Business Roles** Fiori app (replaces PFCG)

## Common Patterns

### Pattern 1: SU53 Error Analysis

```
1. User gets "No authorization" error
2. User runs SU53 immediately
3. SU53 shows:
   - Authorization Object: S_TCODE
   - Field: TCD
   - Required: ME21N
   - User has: ME23N, ME22N (missing ME21N)
4. Fix: Add ME21N to user's role in PFCG
```

For complex cases, use **STAUTHTRACE**:
```
1. STAUTHTRACE → Activate (filter: specific user, errors only)
2. User reproduces the action
3. STAUTHTRACE → Deactivate → Evaluate
4. Shows ALL auth checks with RC=0 (pass) and RC≠0 (fail)
```

### Pattern 2: SoD Conflict Detection

Classic SoD conflicts to check:

| Function A | Function B | Risk |
|-----------|-----------|------|
| Create Vendor (XK01/BP) | Post Vendor Payment (F110) | Fictitious vendor fraud |
| Create PO (ME21N) | Approve PO (ME29N) | Unauthorized procurement |
| Maintain Customer (XD01/BP) | Post Credit Memo (FB75) | Credit fraud |
| Create Employee (PA30) | Run Payroll (PC00_M99) | Ghost employee |
| Maintain GL Master (FS00) | Post Journal Entry (FB50) | Financial misstatement |
| Change User (SU01) | Change Role (PFCG) | Privilege escalation |

### Pattern 3: Security Audit Log Configuration

```
Transaction: RSAU_CONFIG (or SM19 on older systems)

Recommended filters (Dynamic Configuration):
1. Client: *, User: SAP* → Record ALL events (default user monitoring)
2. Client: *, User: FF_* → Record ALL events (firefighter monitoring)
3. Client: *, User: * → Record:
   - Dialog logon (successful + failed)
   - RFC/CPIC logon (successful + failed)
   - Transaction starts
   - Report starts
   - User master changes

Analysis: RSAU_READ_LOG (or SM20)
Enable: Set profile parameter rsau/enable = 1
```

### Pattern 4: BTP Principal Propagation

```
User → IAS (authentication)
     → BTP Subaccount (SAML trust)
     → XSUAA (JWT token)
     → Destination (OAuth2SAMLBearerAssertion)
     → S/4HANA (API call with user identity)

Destination config:
- Type: HTTP
- Authentication: OAuth2SAMLBearerAssertion
- Token Service URL: <S4HANA>/sap/bc/sec/oauth2/token
- Audience: S/4HANA SAML provider name
```

### Pattern 5: GDPR — ILM Data Blocking

```
1. IRM_CUST → Define retention rules per data object and legal entity
2. Configure residence/retention periods (aligned with local tax law)
3. Set up blocking policies (simplified blocking restricts read access)
4. Schedule destruction jobs (permanent erasure after retention expiry)
5. Implement Information Retrieval for data subject access requests

Key transactions: IRM_CUST, IRMPOL, ILM_DESTRUCTION, SARA
```

## Error Catalog

| Error | Cause | Fix |
|-------|-------|-----|
| SU53 shows failed S_RFC check | Missing RFC authorization for function group | Add RFC auth to role: S_RFC with RFC_TYPE=FUGR, RFC_NAME=<group> |
| "No authorization for transaction" | S_TCODE missing in role | PFCG → add transaction to menu → regenerate profile |
| Derived role not working | Master role changed but derived not adjusted | PFCG → open derived role → Adjust (Ctrl+F5) |
| 401 on BTP app | Role collection not assigned | BTP cockpit → assign role collection to user |
| SAML token exchange fails | Audience mismatch in destination | Match destination audience with SAML provider name |
| IPS provisioning fails | Attribute mapping mismatch | Check IPS transformation JSON for correct field names |
| SoD conflict in GRC | Incompatible roles assigned | Add mitigation control or remove one conflicting role |
| Audit log not recording | rsau/enable = 0 or SM19 not configured | Set rsau/enable = 1; configure filters in RSAU_CONFIG |
| User locked after failed logins | Login/password lock parameters exceeded | SU01 → unlock; check login/fails_to_user_lock parameter |
| Certificate expired in trust | SAML metadata signing cert expired | Re-exchange SAML metadata with fresh certificates |

## Performance Tips

- Use **SUIM** reports for bulk authorization analysis (faster than manual SU01 checks)
- **STAUTHTRACE** with "errors only" filter reduces trace volume significantly
- Keep roles modular (5-15 auth objects per single role); composite roles combine them
- In BTP, minimize scope count per role template — JWT token size has limits
- Schedule **RSUSR200** as background job for monthly dormant user detection

## Key Tables

| Table | Content |
|-------|---------|
| AGR_1251 | Role → auth object → field → value |
| AGR_USERS | Role-to-user assignments |
| AGR_DEFINE | Role definitions |
| USR02 | User logon data (lock status, last logon, password hash) |
| USR04 | User-to-profile assignments |
| USOBT_C / USOBX_C | SU24 check indicators |

## Bundled Resources

| File | When to Read |
|------|-------------|
| `references/pfcg-role-design.md` | Detailed PFCG role creation guide |
| `references/authorization-objects.md` | Full reference of critical auth objects |
| `references/sod-matrix.md` | Comprehensive SoD conflict matrix |
| `references/cloud-identity-services.md` | IAS/IPS configuration guide |
| `references/btp-xsuaa-guide.md` | BTP authorization with XSUAA |
| `references/compliance-checklist.md` | SOX, GDPR, ISO 27001 audit checklist |
| `templates/xs-security.json` | BTP xs-security.json template |
| `templates/role-naming-convention.md` | Role naming standard template |

## Source Documentation

- [SAP Help: Authorization Concept](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/4fbc2cfa90ab43bcb7eb61f2b5655e9a)
- [SAP Help: XSUAA Configuration](https://help.sap.com/docs/btp/sap-business-technology-platform/application-security-descriptor-configuration-syntax)
- [SAP Cloud Identity Services](https://help.sap.com/docs/cloud-identity-services)
- [SAP Help: ILM for GDPR](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/d4e7e8f20afa487fb99be3c498f21b44)
- [SAP GRC Access Control](https://help.sap.com/docs/SAP_ACCESS_CONTROL)
