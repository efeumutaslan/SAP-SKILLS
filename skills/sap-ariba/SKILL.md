---
name: sap-ariba
description: |
  SAP Ariba procurement and sourcing development skill. Use when: integrating with Ariba APIs
  (Procurement, Sourcing, Contract, Supplier Management), building custom Ariba extensions,
  working with Ariba Cloud Integration Gateway (CIG), configuring Ariba Network transactions
  (cXML, EDI), developing Ariba custom forms, managing supplier lifecycle events, or integrating
  Ariba with S/4HANA procurement. Covers Ariba APIs, cXML protocol, Open APIs, and integration patterns.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Ariba Procurement & Sourcing

## Related Skills
- `sap-s4hana-extensibility` — S/4HANA MM/procurement integration with Ariba
- `sap-event-mesh` — Event-driven integration between Ariba and BTP
- `sap-security-authorization` — OAuth/certificate setup for Ariba APIs

## Quick Start

**Choose your integration approach:**

| Scenario | API/Protocol | Authentication |
|----------|-------------|----------------|
| Procurement data extract | Ariba Open APIs (REST) | OAuth 2.0 client credentials |
| Transactional documents | cXML over HTTPS | Shared secret |
| Supplier management | Ariba SOAP APIs | Certificate-based |
| S/4HANA integration | Cloud Integration Gateway (CIG) | SAP Integration Suite |
| Custom UI extensions | Ariba Custom Forms | Ariba Developer Portal |

**First API call — Procurement Reporting:**

```bash
# Step 1: Get OAuth token
curl -X POST "https://api.ariba.com/v2/oauth/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id={{CLIENT_ID}}&client_secret={{CLIENT_SECRET}}"

# Step 2: Call Procurement API
curl -X GET "https://openapi.ariba.com/api/procurement-reporting/v2/prod/views/{{VIEW_ID}}" \
  -H "Authorization: Bearer {{TOKEN}}" \
  -H "apiKey: {{API_KEY}}" \
  -H "X-ARIBA-NETWORK-ID: {{AN_ID}}"
```

## Core Concepts

### Ariba Solution Architecture
| Module | Purpose | Key Objects |
|--------|---------|-------------|
| **Ariba Procurement** | Requisitions, POs, Invoices | Requisition, PurchaseOrder, Invoice |
| **Ariba Sourcing** | RFx, Auctions, Contracts | SourcingProject, SourcingRequest |
| **Ariba Contracts** | CLM, compliance | Contract, ContractWorkspace |
| **Ariba Supplier Management** | Qualification, risk | SupplierRegistration, Questionnaire |
| **Ariba Network** | B2B transactions | cXML OrderRequest, InvoiceDetailRequest |
| **Ariba Spend Analysis** | Spend visibility | SpendFact, SpendCategory |

### API Landscape
1. **Open APIs (REST)** — Reporting/analytics, paginated data extraction
2. **Operational APIs (REST)** — CRUD on procurement documents
3. **SOAP APIs** — Legacy supplier/sourcing integration
4. **cXML** — B2B document exchange (PunchOut, OrderRequest, InvoiceDetail)
5. **CIG (Cloud Integration Gateway)** — Mediated S/4HANA ↔ Ariba integration

### cXML Protocol Essentials
- **Envelope**: `<cXML>` → `<Header>` (auth) + `<Request>`/`<Response>`/`<Message>`
- **Authentication**: SharedSecret in `<Credential>` element
- **PunchOut**: Buyer catalog browsing on supplier site → `PunchOutSetupRequest` → `PunchOutOrderMessage`
- **Document flow**: OrderRequest → ConfirmationRequest → ShipNoticeRequest → InvoiceDetailRequest

## Common Patterns

### Pattern 1: cXML OrderRequest

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML SYSTEM "http://xml.cxml.org/schemas/cXML/1.2.060/cXML.dtd">
<cXML payloadID="{{PAYLOAD_ID}}" timestamp="2026-03-24T10:00:00+00:00">
  <Header>
    <From>
      <Credential domain="NetworkId">
        <Identity>{{BUYER_AN_ID}}</Identity>
      </Credential>
    </From>
    <To>
      <Credential domain="NetworkId">
        <Identity>{{SUPPLIER_AN_ID}}</Identity>
      </Credential>
    </To>
    <Sender>
      <Credential domain="NetworkId">
        <Identity>{{BUYER_AN_ID}}</Identity>
        <SharedSecret>{{SHARED_SECRET}}</SharedSecret>
      </Credential>
      <UserAgent>SAP Ariba Procurement</UserAgent>
    </Sender>
  </Header>
  <Request>
    <OrderRequest>
      <OrderRequestHeader orderID="PO-2026-001" orderDate="2026-03-24T10:00:00+00:00" type="new">
        <Total>
          <Money currency="EUR">5000.00</Money>
        </Total>
        <ShipTo>
          <Address addressID="ADDR-001">
            <Name xml:lang="en">Main Warehouse</Name>
          </Address>
        </ShipTo>
        <BillTo>
          <Address addressID="ADDR-002">
            <Name xml:lang="en">Finance Department</Name>
          </Address>
        </BillTo>
      </OrderRequestHeader>
      <ItemOut quantity="100" lineNumber="1">
        <ItemID>
          <SupplierPartID>MAT-001</SupplierPartID>
        </ItemID>
        <ItemDetail>
          <UnitPrice>
            <Money currency="EUR">50.00</Money>
          </UnitPrice>
          <Description xml:lang="en">Office Supplies</Description>
          <UnitOfMeasure>EA</UnitOfMeasure>
        </ItemDetail>
      </ItemOut>
    </OrderRequest>
  </Request>
</cXML>
```

### Pattern 2: Open API Data Extraction with Pagination

```python
import requests

BASE_URL = "https://openapi.ariba.com/api/procurement-reporting/v2/prod"
API_KEY = "{{API_KEY}}"
TOKEN = "{{OAUTH_TOKEN}}"
REALM = "{{REALM_NAME}}"

headers = {
    "Authorization": f"Bearer {TOKEN}",
    "apiKey": API_KEY,
    "Accept": "application/json"
}

def extract_requisitions(date_from, date_to):
    """Extract requisitions using Procurement Reporting API."""
    all_records = []
    page_token = None

    while True:
        params = {
            "realm": REALM,
            "filters": f'{{"createdDateFrom":"{date_from}","createdDateTo":"{date_to}"}}',
            "limit": 100
        }
        if page_token:
            params["pageToken"] = page_token

        resp = requests.get(
            f"{BASE_URL}/views/RequisitionLineItemFact",
            headers=headers, params=params
        )
        resp.raise_for_status()
        data = resp.json()

        all_records.extend(data.get("Records", []))
        page_token = data.get("PageToken")
        if not page_token:
            break

    return all_records
```

### Pattern 3: PunchOut Setup Request

```xml
<cXML payloadID="{{PAYLOAD_ID}}" timestamp="2026-03-24T10:00:00+00:00">
  <Header><!-- credentials --></Header>
  <Request>
    <PunchOutSetupRequest operation="create">
      <BuyerCookie>{{SESSION_ID}}</BuyerCookie>
      <BrowserFormPost>
        <URL>https://buyer-app.example.com/punchout/return</URL>
      </BrowserFormPost>
      <SelectedItem>
        <ItemID>
          <SupplierPartID>CAT-001</SupplierPartID>
        </ItemID>
      </SelectedItem>
    </PunchOutSetupRequest>
  </Request>
</cXML>
```

### Pattern 4: Operational API — Create Requisition

```python
import requests

def create_requisition(token, api_key, realm, req_data):
    """Create purchase requisition via Operational API."""
    url = f"https://openapi.ariba.com/api/procurement/v3/prod/requisitions"
    headers = {
        "Authorization": f"Bearer {token}",
        "apiKey": api_key,
        "Content-Type": "application/json"
    }
    payload = {
        "realm": realm,
        "Requisition": {
            "Name": req_data["name"],
            "Requester": {"UniqueName": req_data["requester"]},
            "LineItems": [
                {
                    "Description": item["description"],
                    "Quantity": item["quantity"],
                    "UnitPrice": {"Amount": item["price"], "Currency": "EUR"},
                    "Commodity": {"UniqueName": item["commodity_code"]},
                    "DeliverTo": item["deliver_to"]
                }
                for item in req_data["items"]
            ]
        }
    }
    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    return resp.json()
```

### Pattern 5: CIG Integration with S/4HANA

```
S/4HANA MM ──► CIG Middleware ──► Ariba Network
  │                                    │
  PurchaseOrder (IDoc/OData)          OrderRequest (cXML)
  │                                    │
  GoodsReceipt ◄── ShipNotice ◄──── ShipNoticeRequest
  │                                    │
  InvoiceVerification ◄───────────── InvoiceDetailRequest
```

**CIG Configuration Checklist:**
1. Enable CIG add-on in Ariba realm administration
2. Configure S/4HANA connection (RFC destination or OData service)
3. Map S/4HANA company codes to Ariba buying organizations
4. Set up document routing rules (PO → cXML, Invoice → IDoc)
5. Activate number range mapping (Ariba doc ID ↔ S/4HANA doc number)
6. Test with Ariba Integration Toolkit (ITK) before go-live

### Pattern 6: Supplier API — Questionnaire Response

```python
def submit_questionnaire_response(token, api_key, realm, supplier_id, questionnaire_id, answers):
    """Submit supplier qualification questionnaire."""
    url = f"https://openapi.ariba.com/api/supplier-management/v1/prod/questionnaires/{questionnaire_id}/responses"
    headers = {
        "Authorization": f"Bearer {token}",
        "apiKey": api_key,
        "Content-Type": "application/json"
    }
    payload = {
        "realm": realm,
        "supplierId": supplier_id,
        "answers": [
            {"questionId": a["id"], "value": a["value"]}
            for a in answers
        ]
    }
    resp = requests.post(url, headers=headers, json=payload)
    resp.raise_for_status()
    return resp.json()
```

## Error Catalog

| Error / HTTP Status | Message | Root Cause | Fix |
|---------------------|---------|------------|-----|
| `401 Unauthorized` | Invalid token | OAuth token expired or wrong credentials | Refresh token; check client_id/secret |
| `403 Forbidden` | Realm access denied | API key not authorized for realm | Verify API key ↔ realm mapping in Ariba Developer Portal |
| `404 Not Found` | View not found | Wrong view name in reporting API | Check available views in API documentation |
| `429 Too Many Requests` | Rate limit exceeded | API throttling (varies by endpoint) | Implement exponential backoff; batch requests |
| `500 Internal Server Error` | Server error | Ariba platform issue | Retry with backoff; check Ariba system status |
| cXML `400` | Parsing error | Malformed cXML or wrong DTD | Validate against cXML DTD; check encoding |
| cXML `401` | Authentication failed | Wrong SharedSecret or domain | Verify credentials in Ariba Network admin |
| cXML `406` | Not Acceptable | Document rejected by business rules | Check Ariba transaction rules configuration |
| CIG sync error | Document mapping failed | Missing field mapping in CIG config | Review CIG mapping rules; check mandatory fields |
| `REALM_NOT_CONFIGURED` | Realm not found | Integration not set up for realm | Complete realm setup in Ariba Developer Portal |

## Performance Tips

1. **Use reporting APIs for bulk data** — Operational APIs are for single-document CRUD; reporting APIs handle millions of records with pagination
2. **Batch cXML documents** — Use `BatchOrderRequest` for multiple POs in one transmission
3. **Cache OAuth tokens** — Tokens are valid for 20 minutes; don't request a new token per API call
4. **Filter at API level** — Use `filters` parameter to narrow date ranges; avoid client-side filtering
5. **Async for large extracts** — Use asynchronous job API for views with >100K records
6. **CIG scheduling** — Schedule CIG sync during off-peak hours; configure retry intervals for failed docs
7. **PunchOut session timeout** — Default 30 min; extend via `Extrinsic` element if supplier catalogs are large
8. **Monitor API quotas** — Each API has daily/hourly limits; track usage via response headers

## Gotchas

- **Realm vs. site**: API calls require realm name (e.g., `mycompany-T` for test), not site URL
- **cXML DTD validation**: Many Ariba endpoints validate against DTD — missing optional elements can cause `406`
- **API versioning**: Open APIs use URL versioning (`/v2/`); always specify version explicitly
- **Timezone handling**: cXML timestamps must include timezone offset; UTC recommended
- **CIG vs. direct integration**: CIG handles transformations but adds latency; for real-time needs, use direct cXML
- **Ariba Network ID format**: `AN01234567890` — always 14 characters with `AN` prefix
