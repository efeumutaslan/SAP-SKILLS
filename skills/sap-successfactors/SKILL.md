---
name: sap-successfactors
description: |
  SAP SuccessFactors HXM development and integration skill. Use when: building SuccessFactors
  extensions, working with OData APIs for Employee Central, configuring intelligent services,
  implementing custom MDF objects, creating integration flows with SAP BTP, using SuccessFactors
  Extension Center, working with People Analytics OData, building composite applications,
  implementing role-based permissions, or extending SuccessFactors with BTP side-by-side apps.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP SuccessFactors HXM Development

## Related Skills
- `sap-security-authorization` — XSUAA/IAS for BTP-side extensions
- `sap-s4hana-extensibility` — Hybrid HR/Finance integration scenarios

## Quick Start

**Choose your development approach:**

| Scenario | Approach | API |
|----------|----------|-----|
| Read/write employee data | OData V2 API | `/odata/v2/` endpoints |
| Custom business objects | MDF (Metadata Framework) | MDF OData API |
| Event-driven extension | Intelligent Services | Event triggers → BTP |
| Analytics / reporting | People Analytics OData | `$metadata` reporting |
| UI extension | Extension Center | Custom UI on SF pages |
| Integration | SAP Integration Suite | Pre-built iFlows |

**Minimal API call — Get employee by ID:**

```http
GET https://<api-server>/odata/v2/User('EMPL001')
  ?$select=userId,firstName,lastName,email,department
  &$format=json
Authorization: Bearer <oauth_token>
```

## Core Concepts

### API Architecture
- **OData V2**: Primary API protocol for all SuccessFactors entities
- **Entity sets**: Map to business objects (User, EmpJob, EmpEmployment, PerPersonal, etc.)
- **Compound Employee API**: Single request for employee + all related entities
- **Associations**: Navigate between entities (`User('ID')/directReports`)
- **Effective dating**: Most HR entities have `startDate`/`endDate` for temporal data

### Metadata Framework (MDF)
- **Generic Objects (GOs)**: Custom business objects defined via MDF
- **Rules engine**: Business rules attached to MDF objects (onInit, onSave, onChange)
- **Picklists**: Reusable value lists for dropdowns
- **Association types**: 1:1, 1:N, configurable navigation
- **MDF OData**: Auto-generated OData endpoints for custom MDF objects

### Permission Model (RBP)
- **Role-Based Permissions (RBP)**: Foundation of SF security
- **Permission roles**: Group of permission grants assigned to users
- **Target population**: Which employees a role can access (granting rules)
- **Permission groups**: Logical grouping of entities and fields
- **Field-level permissions**: Control read/write/hidden per field per role

### Integration Patterns
| Pattern | Tool | When |
|---------|------|------|
| Real-time sync | SAP Integration Suite iFlows | Employee master → S/4HANA |
| Event-driven | Intelligent Services → BTP | React to HR events |
| Batch extract | OData `$filter` with paging | Nightly data sync |
| UI mashup | Extension Center / BTP HTML5 | Embed custom UI in SF |

## Common Patterns

### Pattern 1: Compound Employee API (Efficient Bulk Read)

```http
GET /odata/v2/CompoundEmployee
  ?$filter=lastModifiedDateTime gt datetime'2026-03-01T00:00:00'
  &$select=person/personIdExternal,
           personalInfo/firstName,personalInfo/lastName,
           jobInfo/company,jobInfo/department,jobInfo/jobTitle,
           employmentInfo/startDate
  &$format=json
  &$top=100
  &$skiptoken=<token_from_previous_response>
```

### Pattern 2: Create Custom MDF Object Record

```http
POST /odata/v2/upsert
Content-Type: application/json

{
  "__metadata": {
    "uri": "cust_Equipment('NEW001')"
  },
  "externalCode": "NEW001",
  "cust_name": "MacBook Pro 16",
  "cust_assignedTo": "EMPL001",
  "cust_status": "ASSIGNED",
  "effectiveStartDate": "/Date(1711929600000)/"
}
```

### Pattern 3: Event-Driven Extension (Intelligent Services)

```javascript
// BTP Cloud Foundry / Kyma — handle SF event
const express = require('express');
const app = express();

app.post('/sf-events', (req, res) => {
  const event = req.body;

  switch (event.type) {
    case 'HIRE':
      console.log(`New hire: ${event.userId}, start: ${event.startDate}`);
      // Trigger provisioning: AD account, equipment, onboarding tasks
      provisionNewHire(event.userId);
      break;
    case 'TERMINATION':
      console.log(`Termination: ${event.userId}, last day: ${event.endDate}`);
      // Trigger de-provisioning
      deprovisionEmployee(event.userId);
      break;
  }

  res.status(200).json({ status: 'processed' });
});

app.listen(process.env.PORT || 8080);
```

### Pattern 4: OData Batch Request

```http
POST /odata/v2/$batch HTTP/1.1
Content-Type: multipart/mixed; boundary=batch_001

--batch_001
Content-Type: application/http
Content-Transfer-Encoding: binary

GET User?$filter=department eq 'IT'&$select=userId,firstName,lastName&$top=50 HTTP/1.1
Accept: application/json

--batch_001
Content-Type: application/http
Content-Transfer-Encoding: binary

GET EmpJob?$filter=company eq '1010' and startDate ge datetime'2026-01-01T00:00:00'&$top=50 HTTP/1.1
Accept: application/json

--batch_001--
```

### Pattern 5: OAuth2 SAML Bearer Token Flow

```javascript
const axios = require('axios');
const { SignedXml } = require('xml-crypto');

async function getSFToken(userId) {
  // 1. Generate SAML assertion (signed with X.509 cert)
  const samlAssertion = generateSAMLAssertion(userId);

  // 2. Exchange SAML assertion for OAuth2 token
  const tokenResponse = await axios.post(
    'https://<api-server>/oauth/token',
    new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:saml2-bearer',
      assertion: Buffer.from(samlAssertion).toString('base64'),
      client_id: '<api_key>',
      company_id: '<company_id>'
    }),
    { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
  );

  return tokenResponse.data.access_token;
}
```

### Pattern 6: People Analytics OData Report

```http
GET /odata/v2/cust_headcountReport
  ?$filter=asOfDate eq datetime'2026-03-24T00:00:00'
  &$select=department,headcount,fte,avgTenure
  &$orderby=department asc
  &$format=json
```

## Error Catalog

| HTTP Status | Error | Root Cause | Fix |
|-------------|-------|------------|-----|
| `401` | `Invalid OAuth token` | Token expired or wrong API server | Refresh token; verify token URL matches API server region |
| `403` | `Insufficient permissions` | RBP role missing for entity/field | Check Admin Center → Manage Permission Roles; add entity permissions |
| `400` | `Invalid effective date` | Date format wrong or future-dated insert blocked | Use `/Date(epoch)/` format; check date restrictions on entity |
| `404` | `Entity not found` | Wrong entity name or entity not enabled | Check `$metadata`; some entities need activation in Provisioning |
| `429` | `Rate limit exceeded` | Too many API calls per minute | Implement exponential backoff; use `$batch` for bulk operations |
| `500` | `Business rule validation failed` | MDF rule rejected the data | Check Manage Business Rules for the object; review rule conditions |

## Performance Tips

1. **Use `$select`** — Always specify needed fields; SF returns ALL fields by default (very slow)
2. **Compound Employee API** — One call vs. 5-10 separate entity calls per employee
3. **`$batch` requests** — Group up to 100 operations in one HTTP call; reduces round-trips
4. **Paging with `$skiptoken`** — Never use `$skip` for large datasets; use server-driven paging
5. **`lastModifiedDateTime` filter** — Delta sync instead of full extract
6. **Cache `$metadata`** — Metadata response is large (>1 MB); cache it, refresh daily
7. **Avoid deep expansions** — `$expand` with 3+ levels causes timeouts; use separate queries
8. **Time zone awareness** — All dates in UTC; convert at display layer, not in API queries

## Gotchas

- **Effective dating**: Every update to EmpJob, EmpEmployment, etc. requires `startDate`; omitting it creates records effective "today" which may conflict with existing records
- **Picklist values**: Use `picklistId` + `optionId`, NOT display text — display text is locale-dependent
- **API server vs. data center**: Token endpoint and API base URL may be different hostnames
- **SAML assertion clock skew**: Assertions must have `NotBefore` / `NotOnOrAfter` within 5 min of server time
- **MDF field limits**: Custom MDF objects max 150 fields; plan field usage carefully
- **Integration Center vs. Suite**: Integration Center (within SF) for simple scenarios; SAP Integration Suite for complex multi-system flows
