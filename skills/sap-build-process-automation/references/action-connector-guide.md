# Action Connector Guide — Connecting SBPA to External Systems

## Overview

Actions are the mechanism SBPA uses to call external APIs. An Action Project wraps
an OData or REST API specification and exposes it as a reusable step in workflows.

## Architecture

```
SBPA Process
  └── Action Step
        └── Action Project (OData/REST spec)
              └── BTP Destination
                    └── Target System (S/4HANA, SuccessFactors, custom API)
```

## Creating an Action Project

### Step 1: Create Project
```
SAP Build Lobby → Create → Action Project
Name: S4HANA_PurchaseOrder_Actions
Description: Purchase Order operations on S/4HANA
```

### Step 2: Import API Specification

**For OData APIs:**
1. Download metadata from S/4HANA: `https://<host>/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/$metadata`
2. Or get from SAP API Business Hub: api.sap.com → Download specification
3. Import the `.edmx` file into the Action Project

**For REST APIs:**
1. Prepare OpenAPI 3.0 / Swagger specification (`.json` or `.yaml`)
2. Import into the Action Project

### Step 3: Select Operations
After import, choose which API operations to expose:
- `GET /A_PurchaseOrder` → List purchase orders
- `POST /A_PurchaseOrder` → Create purchase order
- `PATCH /A_PurchaseOrder('{PurchaseOrder}')` → Update purchase order
- `POST /A_PurchaseOrder('{PurchaseOrder}')/Release` → Release PO

### Step 4: Configure Input/Output Mappings
- Map process variables to API request fields
- Map API response fields to process variables
- Set default values for optional fields

## Destination Configuration

### Required Destination Properties

The BTP destination MUST have these additional properties for SBPA:

| Property | Value | Required |
|----------|-------|----------|
| `sap.processautomation.enabled` | `true` | Yes — without this, SBPA cannot see the destination |
| `sap.applicationdevelopment.actions.enabled` | `true` | Yes — enables Actions feature |
| `URL.headers.Content-Type` | `application/json` | Recommended |
| `HTML5.DynamicDestination` | `true` | For HTML5 apps |

### Destination Types

#### OAuth2 Client Credentials (Service-to-Service)
```json
{
  "Name": "S4HANA_CC",
  "Type": "HTTP",
  "URL": "https://my-s4.s4hana.ondemand.com",
  "ProxyType": "Internet",
  "Authentication": "OAuth2ClientCredentials",
  "tokenServiceURL": "https://my-s4.authentication.eu10.hana.ondemand.com/oauth/token",
  "clientId": "<communication_user_client_id>",
  "clientSecret": "<communication_user_client_secret>",
  "sap.processautomation.enabled": "true",
  "sap.applicationdevelopment.actions.enabled": "true"
}
```

#### OAuth2 SAML Bearer (User Propagation)
```json
{
  "Name": "S4HANA_SAML",
  "Type": "HTTP",
  "URL": "https://my-s4.s4hana.ondemand.com",
  "ProxyType": "Internet",
  "Authentication": "OAuth2SAMLBearerAssertion",
  "audience": "https://my-s4.s4hana.ondemand.com",
  "authnContextClassRef": "urn:oasis:names:tc:SAML:2.0:ac:classes:X509",
  "tokenServiceURL": "https://my-s4.s4hana.ondemand.com/sap/bc/sec/oauth2/token",
  "tokenServiceUser": "<communication_user>",
  "tokenServicePassword": "<password>",
  "sap.processautomation.enabled": "true",
  "sap.applicationdevelopment.actions.enabled": "true"
}
```

#### Basic Authentication (Simple, not recommended for production)
```json
{
  "Name": "S4HANA_Basic",
  "Type": "HTTP",
  "URL": "https://my-s4.s4hana.ondemand.com",
  "ProxyType": "Internet",
  "Authentication": "BasicAuthentication",
  "User": "<username>",
  "Password": "<password>",
  "sap.processautomation.enabled": "true",
  "sap.applicationdevelopment.actions.enabled": "true"
}
```

#### On-Premise via Cloud Connector
```json
{
  "Name": "S4HANA_OnPrem",
  "Type": "HTTP",
  "URL": "http://s4hana.internal:8000",
  "ProxyType": "OnPremise",
  "Authentication": "PrincipalPropagation",
  "sap.processautomation.enabled": "true",
  "sap.applicationdevelopment.actions.enabled": "true",
  "CloudConnectorLocationId": "<location_id>"
}
```

## Destination Variables (Multi-Environment)

Use destination variables to support dev/test/prod without code changes:

### Step 1: Define Variable in Action Project
```
In Action Project → Settings → Destination Variable
Variable Name: S4_DESTINATION
```

### Step 2: Map at Deployment
```
Deploy → Environment Variables
S4_DESTINATION = "S4HANA_DEV"  (for dev)
S4_DESTINATION = "S4HANA_PROD" (for prod)
```

This way, the same process definition uses different destinations per environment.

## Common Action Patterns

### Pattern 1: Create S/4HANA Purchase Order
```
Action: POST /A_PurchaseOrder
Input Mapping:
  CompanyCode     ← process.companyCode
  PurchaseOrderType ← "NB"
  Supplier        ← process.vendorId
  PurchasingOrganization ← process.purchOrg

Output Mapping:
  process.poNumber ← PurchaseOrder
  process.status   ← "Created"
```

### Pattern 2: Read + Check + Update
```
Step 1: Action GET /A_PurchaseOrder('{PurchaseOrder}')
  → Read current PO status

Step 2: Condition
  IF status = "Released" → proceed
  ELSE → route to manual review

Step 3: Action PATCH /A_PurchaseOrder('{PurchaseOrder}')
  → Update PO fields
```

### Pattern 3: Error Handling in Actions
```
Action Step → Output
  On Success: Continue to next step
  On Error:
    HTTP 400 → Route to "Fix Data" form
    HTTP 401 → Route to "Re-authenticate" step
    HTTP 404 → Route to "Object Not Found" notification
    HTTP 500 → Route to "System Error" notification + retry after delay
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| "No destinations found" | Missing `sap.processautomation.enabled` property | Add property to destination |
| "403 Forbidden" | Destination user lacks API permissions | Check Communication Arrangement in S/4HANA |
| "Connection timeout" | On-premise system unreachable | Check Cloud Connector status and virtual host mapping |
| "SSL handshake failed" | Certificate not trusted | Import target system certificate into BTP destination trust store |
| "Action returns empty" | Response mapping mismatch | Check API response structure matches expected output mapping |
| "CSRF token validation failed" | OData service requires CSRF | Enable "Fetch CSRF Token" in destination or action config |
| "Destination variable not set" | Missing environment variable at deploy time | Set destination variable in deployment configuration |

## Best Practices

1. **Use OAuth2 Client Credentials** for service-to-service (no user context needed)
2. **Use OAuth2 SAML Bearer** when the API needs to know WHO triggered the action
3. **Use destination variables** for environment-independent processes
4. **Add error handling** in process flow for every Action step
5. **Test API calls independently** before embedding in a process (use Postman/Insomnia)
6. **Version Action Projects** alongside Process Projects
7. **Cache API responses** when the same data is needed in multiple process steps
8. **Set reasonable timeouts** — default may be too short for complex APIs
