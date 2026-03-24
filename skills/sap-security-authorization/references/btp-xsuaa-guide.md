# BTP Authorization with XSUAA — Developer Guide

## Overview

XSUAA (XS Advanced UAA) is the authorization service for SAP BTP Cloud Foundry.
It issues JWT tokens containing user scopes based on assigned role collections.

## Authorization Hierarchy

```
Scope (defined in xs-security.json)
  └── Role Template (groups scopes)
        └── Role (instance of role template, may have attributes)
              └── Role Collection (groups roles, assignable to users/groups)
                    └── User / User Group
```

## xs-security.json — Complete Reference

```json
{
  "xsappname": "myapp",
  "tenant-mode": "dedicated",
  "description": "Application security descriptor",

  "scopes": [
    {
      "name": "$XSAPPNAME.Read",
      "description": "Read application data"
    },
    {
      "name": "$XSAPPNAME.Write",
      "description": "Modify application data"
    },
    {
      "name": "$XSAPPNAME.Admin",
      "description": "Administrative functions"
    },
    {
      "name": "$XSAPPNAME.Callback",
      "description": "SaaS provisioning callback",
      "grant-as-authority-to-apps": ["$XSAPPNAME(application,sap-provisioning,tenant-onboarding)"]
    }
  ],

  "attributes": [
    {
      "name": "CompanyCode",
      "description": "Restrict by company code",
      "valueType": "string",
      "valueRequired": false
    },
    {
      "name": "CostCenter",
      "description": "Restrict by cost center",
      "valueType": "string",
      "valueRequired": false
    }
  ],

  "role-templates": [
    {
      "name": "Viewer",
      "description": "Read-only access to application",
      "scope-references": ["$XSAPPNAME.Read"],
      "attribute-references": ["CompanyCode"]
    },
    {
      "name": "Editor",
      "description": "Read and write access",
      "scope-references": ["$XSAPPNAME.Read", "$XSAPPNAME.Write"],
      "attribute-references": ["CompanyCode", "CostCenter"]
    },
    {
      "name": "Administrator",
      "description": "Full access including admin",
      "scope-references": [
        "$XSAPPNAME.Read",
        "$XSAPPNAME.Write",
        "$XSAPPNAME.Admin"
      ]
    },
    {
      "name": "Token_Exchange",
      "description": "UAA token exchange for service-to-service",
      "scope-references": ["uaa.user"]
    }
  ],

  "role-collections": [
    {
      "name": "MyApp_Viewer",
      "description": "View application data",
      "role-template-references": ["$XSAPPNAME.Viewer"]
    },
    {
      "name": "MyApp_Editor",
      "description": "Edit application data",
      "role-template-references": ["$XSAPPNAME.Editor"]
    },
    {
      "name": "MyApp_Admin",
      "description": "Full administration",
      "role-template-references": ["$XSAPPNAME.Administrator"]
    }
  ],

  "oauth2-configuration": {
    "token-validity": 43200,
    "refresh-token-validity": 604800,
    "redirect-uris": [
      "https://myapp.cfapps.eu10.hana.ondemand.com/**"
    ]
  }
}
```

## Checking Scopes in Application Code

### Node.js (CAP)
```javascript
// In .cds service definition
service CatalogService @(requires: 'authenticated-user') {
  entity Products @(restrict: [
    { grant: 'READ', to: 'Viewer' },
    { grant: ['CREATE', 'UPDATE'], to: 'Editor' },
    { grant: '*', to: 'Admin' }
  ]) as projection on db.Products;
}
```

### Node.js (Express with Passport)
```javascript
const xsenv = require('@sap/xsenv');
const passport = require('passport');
const { JWTStrategy } = require('@sap/xssec');

const services = xsenv.getServices({ uaa: { tag: 'xsuaa' } });
passport.use(new JWTStrategy(services.uaa));

app.use(passport.initialize());
app.use(passport.authenticate('JWT', { session: false }));

app.get('/api/data', (req, res) => {
  // Check scope
  if (!req.authInfo.checkScope('$XSAPPNAME.Read')) {
    return res.status(403).json({ error: 'Insufficient scope' });
  }

  // Get attribute values
  const companyCodes = req.authInfo.getAttribute('CompanyCode');
  // companyCodes = ['1000', '2000'] (from role collection attribute assignment)

  // Filter data by user's company codes
  const data = getDataForCompanyCodes(companyCodes);
  res.json(data);
});
```

### Java (Spring Boot)
```java
@RestController
@RequestMapping("/api")
public class DataController {

    @GetMapping("/data")
    @PreAuthorize("hasAuthority('Read')")
    public ResponseEntity<List<Data>> getData(
            @AuthenticationPrincipal Token token) {

        // Get attribute values
        String[] companyCodes = token.getAttributeValues("CompanyCode");

        // Check specific scope
        if (token.hasLocalScope("Admin")) {
            return ResponseEntity.ok(getAllData());
        }

        return ResponseEntity.ok(getDataForCompanyCodes(companyCodes));
    }
}
```

### ABAP (RAP on BTP)
```abap
" In RAP authorization handler
METHOD get_global_authorizations.
  " XSUAA scopes are mapped to authorization objects in Communication Scenario
  " The framework handles the mapping automatically
  IF requested_authorizations-%create = if_abap_behv=>mk-on.
    " Check is done against XSUAA scope via Communication Arrangement
    result-%create = COND #(
      WHEN cl_abap_context_info=>get_user_technical_name( ) IS NOT INITIAL
      THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).
  ENDIF.
ENDMETHOD.
```

## Service-to-Service Communication

### Client Credentials Grant
For backend-to-backend (no user context):
```json
// Destination or manual token fetch
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&
client_id=<xsuaa_client_id>&
client_secret=<xsuaa_client_secret>
```

### User Token Exchange (Principal Propagation)
For forwarding user identity to another service:
```json
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&
client_id=<xsuaa_client_id>&
client_secret=<xsuaa_client_secret>&
assertion=<user_jwt_token>&
response_type=token
```

### Named User Token Exchange
For getting a token with named user's identity:
```json
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:saml2-bearer&
client_id=<xsuaa_client_id>&
client_secret=<xsuaa_client_secret>&
assertion=<base64_encoded_saml_assertion>
```

## Debugging Authorization Issues

### Step 1: Decode JWT Token
```bash
# Get token from app (browser dev tools → Network → Authorization header)
# Decode at jwt.io or:
echo "<jwt_token>" | cut -d'.' -f2 | base64 -d | jq .
```

### Step 2: Check Token Contents
```json
{
  "scope": [
    "myapp!t12345.Read",
    "myapp!t12345.Write",
    "openid"
  ],
  "xs.user.attributes": {
    "CompanyCode": ["1000", "2000"]
  },
  "grant_type": "authorization_code",
  "user_name": "john.doe@company.com"
}
```

### Step 3: Verify Against xs-security.json
- Are the expected scopes present in the token?
- Are attribute values correct?
- Does the role collection have the right role templates?

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Scope missing in JWT | Role collection not assigned | BTP cockpit → assign role collection |
| Attribute empty | Attribute not configured in role | BTP cockpit → edit role → set attribute values |
| 401 Unauthorized | XSUAA binding missing | `cf bind-service app xsuaa-instance` |
| 403 Forbidden | Scope check failing | Verify scope name matches `$XSAPPNAME.<scope>` |
| Token too large | Too many scopes/roles | Reduce role collection assignments; use attribute-based |
| Token expired | Default 12h validity | Refresh token or adjust `token-validity` |

## Multi-Tenancy Considerations

For SaaS apps with `"tenant-mode": "shared"`:
- Each subscriber tenant gets its own XSUAA instance
- Scopes are prefixed with tenant-specific `$XSAPPNAME`
- Role collections must be created per tenant (or use default role collections)
- Tenant admin creates/assigns role collections in subscriber BTP cockpit

## Best Practices

1. **Principle of least privilege**: Define minimum scopes needed per role
2. **Use attributes for data-level security**: Don't create scope per org-unit
3. **Separate admin and business scopes**: Admins should not need business scopes
4. **Use role collections for assignment**: Never assign roles directly
5. **Group mapping**: Map IAS/corporate IdP groups to role collections for automated assignment
6. **Audit**: Regularly review role collection assignments in BTP cockpit
7. **Token size**: Keep total scopes <50 per user to avoid token size issues
