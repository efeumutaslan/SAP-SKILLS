# SAP Cloud Identity Services (IAS / IPS) — Configuration Guide

## Architecture

```
Corporate IdP (Azure AD, Okta, ADFS)
        │
        ▼
SAP Identity Authentication (IAS) ←── Proxy or Primary IdP
        │
        ├── SSO to SAP BTP apps
        ├── SSO to S/4HANA Cloud
        ├── SSO to SuccessFactors
        └── SSO to other SAP cloud products
        │
SAP Identity Provisioning (IPS) ←── User sync
        │
        ├── Source: Azure AD / IAS / SuccessFactors
        └── Target: BTP subaccounts / S/4HANA Cloud / IAS
```

## IAS (Identity Authentication)

### Admin Console Access
```
URL: https://<tenant-id>.accounts.ondemand.com/admin
Tenant ID: Found in BTP cockpit → Security → Trust Configuration
```

### Configuration Steps

#### Step 1: Trust Configuration (Corporate IdP as Proxy)
```
1. IAS Admin → Identity Providers → Corporate Identity Providers → Add
2. Upload IdP SAML metadata XML (from Azure AD / Okta / ADFS)
3. Configure:
   - Name ID format: Email or Login Name
   - Assertion attributes: email, firstName, lastName, groups
4. Set as default IdP for all applications (or per-application routing)
```

**Proxy mode** (recommended): IAS acts as a proxy/broker to the corporate IdP.
Users authenticate at the corporate IdP; IAS forwards assertions to SAP apps.

#### Step 2: Application Registration
```
1. IAS Admin → Applications & Resources → Applications → Add
2. Set:
   - Display Name: "My BTP App"
   - Type: SAP BTP solution
   - Protocol: SAML 2.0 or OpenID Connect
3. Configure SAML settings:
   - Upload SP metadata from the target application
   - Or manually configure ACS URL, Entity ID
4. Configure assertion attributes:
   - Map corporate IdP attributes to SAP attributes
   - Common mappings: mail→email, sAMAccountName→loginName
```

#### Step 3: Authentication Methods
```
IAS Admin → Applications → [App] → Authentication & Access
Options:
- Password: IAS-managed passwords (for IAS-primary scenarios)
- SPNEGO/Kerberos: Windows integrated auth
- X.509 Client Certificates: Certificate-based auth
- Two-Factor Authentication: TOTP, SMS
- Social Login: Google, Apple, Facebook
- Risk-Based Authentication: IP ranges, user type, geo-location
```

#### Step 4: Conditional Authentication
```
IAS Admin → Applications → [App] → Conditional Authentication
Rules:
- IF user_type = employee → redirect to Corporate IdP
- IF user_type = customer → use IAS password
- IF IP NOT IN corporate_range → require MFA
- IF group = admin → require certificate
```

### Troubleshooting IAS

| Issue | Check |
|-------|-------|
| Login loop | SAML metadata mismatch (entity ID, ACS URL) |
| "User not found" | User not provisioned to target app; check IPS |
| Certificate error | IdP signing certificate expired; re-exchange metadata |
| Attribute missing | Check assertion attribute mapping in IAS app config |
| MFA not triggering | Risk-based auth rules order (first match wins) |

## IPS (Identity Provisioning)

### Concepts
- **Source System**: Where users originate (Azure AD, SuccessFactors, IAS)
- **Target System**: Where users are provisioned to (BTP, S/4HANA Cloud, IAS)
- **Transformations**: JSON rules mapping source attributes to target format
- **Jobs**: Scheduled or manual sync operations

### Configuration Steps

#### Step 1: Add Source System
```
IPS Admin → Source Systems → Add
Type: Microsoft Azure AD (SCIM 2.0)
Connection:
- URL: https://graph.microsoft.com/v1.0
- OAuth Client ID: <from Azure App Registration>
- OAuth Client Secret: <from Azure>
- OAuth Token URL: https://login.microsoftonline.com/<tenant>/oauth2/v2.0/token
```

#### Step 2: Add Target System
```
IPS Admin → Target Systems → Add
Type: SAP BTP Cloud Foundry (SCIM 2.0)
Connection:
- URL: https://api.authentication.<region>.hana.ondemand.com
- OAuth Client ID: <from BTP service key>
- OAuth Client Secret: <from BTP service key>
```

#### Step 3: Configure Transformations
```json
{
  "user": {
    "mappings": [
      {
        "sourceVariable": "entityIdTargetSystem",
        "targetPath": "$.schemas"
      },
      {
        "sourcePath": "$.userName",
        "targetPath": "$.userName"
      },
      {
        "sourcePath": "$.emails[0].value",
        "targetPath": "$.emails[0].value"
      },
      {
        "sourcePath": "$.name.givenName",
        "targetPath": "$.name.givenName"
      },
      {
        "sourcePath": "$.name.familyName",
        "targetPath": "$.name.familyName"
      },
      {
        "sourcePath": "$.groups",
        "targetPath": "$.groups",
        "optional": true
      }
    ]
  }
}
```

#### Step 4: Schedule Jobs
```
IPS Admin → Source System → [System] → Jobs
- Read: Full sync (reads all users from source, compares with target, syncs delta)
- Validate: Dry-run without making changes
- Schedule: Recurring sync (e.g., every 6 hours)
```

### Troubleshooting IPS

| Issue | Check |
|-------|-------|
| "No users provisioned" | Source system filter excluding users; check read transformation |
| Attribute error | Transformation JSON syntax; check sourcePath/targetPath |
| Duplicate user | Same user provisioned from multiple sources; check conflict resolution |
| Group sync fails | Target system doesn't support groups; check target capabilities |
| Job timeout | Too many users for single sync; use pagination settings |

## Critical Deadlines

| Date | Event |
|------|-------|
| 2025-06-02 | Basic auth + third-party IdP direct integration end of maintenance (SuccessFactors) |
| 2026-11-01 | These methods deleted — IAS migration mandatory |

## Common Architecture Patterns

### Pattern 1: IAS as Proxy (Recommended)
```
Users → Corporate IdP (Azure AD) → IAS (proxy) → SAP Applications
Benefits: Single IdP management, IAS provides consistent SAP SSO
```

### Pattern 2: IAS as Primary IdP
```
Users → IAS (with own user store) → SAP Applications
Use case: External users (customers, partners) without corporate IdP
```

### Pattern 3: Hybrid (Multiple IdPs)
```
Employees → Corporate IdP → IAS → SAP Apps
Customers → IAS (password/social login) → SAP Apps
Partners → Partner IdP → IAS (proxy) → SAP Apps
Routing: Conditional authentication rules in IAS
```

## Group-to-Role Mapping

Map corporate IdP groups to SAP BTP role collections:

```
1. IAS Admin → Application → Assertion Attributes
   → Add attribute: "groups" from corporate IdP

2. BTP Cockpit → Security → Trust Configuration → [IAS]
   → Role Collection Mapping:
     Corporate Group: "SAP_Admins" → Role Collection: "Global Administrator"
     Corporate Group: "SAP_Viewers" → Role Collection: "Global Auditor"
```

This eliminates per-user role assignment in BTP — managed via corporate AD groups.
