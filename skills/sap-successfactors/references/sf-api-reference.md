# SAP SuccessFactors — API Quick Reference

## API Types

| API Type | Base URL | Auth | Use Case |
|----------|----------|------|----------|
| OData V2 | `/odata/v2/` | OAuth2 / SAML | Most SF entities |
| OData V4 | `/odata/v4/` | OAuth2 | Newer entities (limited) |
| SFAPI (SOAP) | `/sfapi/v1/` | Basic Auth | Legacy, being deprecated |
| Intelligent Services | `/api/` | OAuth2 | AI-powered features |

## Key OData V2 Entities

### Employee Central
| Entity | Path | Description |
|--------|------|-------------|
| `User` | `/odata/v2/User` | Employee master data |
| `EmpEmployment` | `/odata/v2/EmpEmployment` | Employment details |
| `EmpJob` | `/odata/v2/EmpJob` | Job information history |
| `EmpCompensation` | `/odata/v2/EmpCompensation` | Compensation data |
| `PerPersonal` | `/odata/v2/PerPersonal` | Personal information |
| `FOCompany` | `/odata/v2/FOCompany` | Company structure |
| `FODepartment` | `/odata/v2/FODepartment` | Department structure |
| `FOJobCode` | `/odata/v2/FOJobCode` | Job classification |
| `Position` | `/odata/v2/Position` | Position management |

### Recruiting
| Entity | Path | Description |
|--------|------|-------------|
| `JobRequisition` | `/odata/v2/JobRequisition` | Open positions |
| `JobApplication` | `/odata/v2/JobApplication` | Applications |
| `Candidate` | `/odata/v2/Candidate` | External candidates |

### Performance & Goals
| Entity | Path | Description |
|--------|------|-------------|
| `Goal_1` | `/odata/v2/Goal_1` | Goals (plan-specific) |
| `FormHeader` | `/odata/v2/FormHeader` | Performance review forms |

### Time & Leave
| Entity | Path | Description |
|--------|------|-------------|
| `EmployeeTime` | `/odata/v2/EmployeeTime` | Time records |
| `TimeAccount` | `/odata/v2/TimeAccount` | Leave balances |
| `TimeAccountType` | `/odata/v2/TimeAccountType` | Leave types config |

## Common Query Patterns

```http
# Get employee with expand
GET /odata/v2/User('EMP001')?$select=firstName,lastName,email
  &$expand=empInfo/jobInfoNav

# Filter by date (effective-dated)
GET /odata/v2/EmpJob?$filter=userId eq 'EMP001'
  and startDate le datetime'2025-03-15T00:00:00'
  and endDate ge datetime'2025-03-15T00:00:00'

# Pagination
GET /odata/v2/User?$top=100&$skip=0&$inlinecount=allpages

# Compound employee (full record)
GET /odata/v2/User('EMP001')?$select=firstName,lastName
  &$expand=empInfo/jobInfoNav,empInfo/compInfoNav,
  personalInfoNav,phoneNav,emailNav

# Upsert (via custom MDF entity)
POST /odata/v2/upsert
Content-Type: application/json
{
  "__metadata": { "uri": "cust_CustomEntity" },
  "externalCode": "REC001",
  "cust_field1": "value1"
}
```

## MDF (Metadata Framework) Custom Objects

```http
# Read custom MDF entity
GET /odata/v2/cust_MyCustomObject?$filter=externalCode eq 'REC001'

# Create MDF record
POST /odata/v2/upsert
{
  "__metadata": { "uri": "cust_MyCustomObject" },
  "externalCode": "NEW001",
  "cust_name": "Test Record",
  "cust_status": "active",
  "effectiveStartDate": "/Date(1710460800000)/"
}
```

## Integration Center (BTP)

```json
// Event-driven integration via SuccessFactors Intelligent Services
{
  "event": "onHire",
  "entity": "EmpEmployment",
  "fields": ["userId", "startDate", "company", "department"],
  "target": {
    "type": "BTP_EVENT_MESH",
    "topic": "sap/successfactors/employee/hired"
  }
}
```

## Authentication — OAuth2 SAML Bearer

```bash
# Step 1: Get SAML assertion (from IdP or SF token endpoint)
# Step 2: Exchange for OAuth2 token
curl -X POST "https://<api-server>/oauth/token" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:saml2-bearer" \
  -d "company_id={{COMPANY_ID}}" \
  -d "client_id={{CLIENT_ID}}" \
  -d "assertion={{BASE64_SAML_ASSERTION}}"
```
