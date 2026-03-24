---
name: sap-build-apps
description: >
  SAP Build Apps (formerly AppGyver) low-code/no-code development skill. Use when building
  visual applications with drag-drop UI, data integration via BTP destinations, formula-based
  logic, or deploying web/mobile apps to BTP. If the user mentions Build Apps, AppGyver,
  low-code SAP app, visual formula, or no-code mobile app on BTP, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Build Apps (Low-Code/No-Code)

## Related Skills
- `sap-build-process-automation` — Trigger workflows from Build Apps
- `sap-s4hana-extensibility` — Consume S/4HANA APIs in Build Apps
- `sap-security-authorization` — BTP authentication for Build Apps

## Quick Start

**Getting started:**
1. Open SAP Build Lobby → Create → Build an Application → Web & Mobile Application
2. Choose template or start blank
3. Three main editors: **UI Canvas** (drag-drop), **Data** (integrations), **Logic** (flow functions)

**Development flow:**
```
Design UI ──► Connect Data ──► Add Logic ──► Preview ──► Build ──► Deploy
  │              │                │
  Canvas     Destinations/     Flow functions
  + Theme    OData/REST        + Formulas
```

## Core Concepts

### Application Types
| Type | Platform | Deployment |
|------|----------|-----------|
| Web App | Browser | BTP HTML5 Repository |
| Mobile (PWA) | iOS/Android browser | BTP + app icon |
| Mobile (Native) | iOS/Android native | App Store / Google Play via Build |

### Data Integration Options
| Source | Method | Setup |
|--------|--------|-------|
| SAP S/4HANA | BTP Destination + OData | Destination config in BTP cockpit |
| SAP SuccessFactors | BTP Destination + OData | Destination with OAuth2SAMLBearer |
| REST API | Direct REST integration | URL + auth headers |
| Firebase/Supabase | Visual Cloud Functions | API connector |
| Local (On-device) | On-device storage | Built-in, no config needed |
| BTP CAP | BTP Destination + OData | Destination to CAP service URL |

### Variable Types
| Variable | Scope | Use Case |
|----------|-------|----------|
| **App Variable** | Global, in-memory | User session state, auth token |
| **Page Variable** | Single page | Form inputs, UI state |
| **Data Variable** | Bound to data resource | API data (auto-fetch/refresh) |
| **Page Parameter** | Passed between pages | Navigation context (record ID) |
| **Translation Variable** | Global | Multi-language strings |

### Formula Language
```
// String
CONCATENATE("Hello, ", pageVars.userName)
UPPERCASE(data.customer.name)
FORMAT_LOCALIZED_DECIMAL(outputs.price, "en", 2)

// List operations
MAP(data.Orders, {id: item.ID, label: item.description})
SELECT(data.Orders, item.status == "Open")
SUM(MAP(data.OrderItems, item.quantity * item.unitPrice))
COUNT(data.Orders)

// Conditional
IF(pageVars.isAdmin, "Admin Panel", "User Dashboard")
IF(IS_EMPTY(data.results), "No results found", "Found " + COUNT(data.results))

// Date
FORMAT_DATETIME_LOCAL(NOW(), "YYYY-MM-DD")
DATETIME_DIFFERENCE(data.order.createdAt, NOW(), "days")
```

## Common Patterns

### Pattern 1: OData Integration via BTP Destination

**BTP Destination setup:**
```properties
Name=S4HANA_ODATA
Type=HTTP
URL=https://my-s4.example.com/sap/opu/odata/sap/
ProxyType=Internet
Authentication=OAuth2SAMLBearerAssertion
Audience=https://my-s4.example.com
tokenServiceURL=https://my-s4.example.com/sap/bc/sec/oauth2/token
```

**In Build Apps:**
1. Data tab → Add Integration → SAP BTP Destination
2. Select destination → Browse available OData services
3. Select entity set → Enable CRUD operations as needed
4. Data variable auto-generates with pagination support

### Pattern 2: Page Navigation with Parameters

```
// On list item tap:
Logic Flow:
  [Component Tap] ──► [Open Page]
                        Page: DetailPage
                        Parameters:
                          orderId = repeated.current.ID
                          orderTitle = repeated.current.description

// On DetailPage:
  [Page Mounted] ──► [Get Record]
                       Resource: Orders
                       ID: pageParams.orderId
                   ──► [Set Page Variable]
                         Variable: orderDetail
                         Value: outputs["Get Record"].record
```

### Pattern 3: Form with Validation

```
// Page variables:
formData = { name: "", email: "", phone: "" }
errors = { name: "", email: "", phone: "" }
isValid = false

// Validation formula (bound to Save button Disabled property):
IF(
  IS_EMPTY(pageVars.formData.name) ||
  !MATCHES(pageVars.formData.email, "^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$") ||
  LENGTH(pageVars.formData.phone) < 10,
  true,
  false
)

// Save logic flow:
[Button Tap] ──► [If Condition: isValid]
                   ├─ True ──► [Create Record] ──► [Toast: "Saved!"] ──► [Navigate Back]
                   └─ False ──► [Set Variable: errors] ──► [Toast: "Fix errors"]
```

### Pattern 4: Authentication Flow

```
// App launch logic (Global Canvas):
[App Launched] ──► [Get Auth Token]
               ──► [If: IS_EMPTY(token)]
                     ├─ True ──► [Open BTP Login Page]
                     └─ False ──► [Set App Variable: authToken]
                               ──► [Set App Variable: currentUser]

// For every API call, add header:
Authorization: Bearer {appVars.authToken}
```

### Pattern 5: Offline-Capable App

```
// Strategy: Cache data locally, sync when online

[Page Mounted] ──► [If: IS_ONLINE]
                     ├─ True ──► [Get Collection] ──► [Set On-Device Storage]
                     └─ False ──► [Get On-Device Storage] ──► [Set Data Variable]

// On form submit (offline-aware):
[Submit] ──► [If: IS_ONLINE]
               ├─ True ──► [Create Record (API)] ──► [Toast: "Saved"]
               └─ False ──► [Append to On-Device Queue]
                          ──► [Toast: "Saved offline, will sync"]

// Sync queue when back online:
[Connectivity Changed: Online] ──► [Get On-Device Queue]
                               ──► [Loop: Create Record for each]
                               ──► [Clear Queue]
```

### Pattern 6: Integration with SAP Build Process Automation

```
// Trigger workflow from Build Apps:
[Submit Button] ──► [HTTP Request]
                      Method: POST
                      URL: {appVars.spaBaseUrl}/workflow/rest/v1/workflow-instances
                      Headers:
                        Authorization: Bearer {appVars.authToken}
                        Content-Type: application/json
                      Body:
                        {
                          "definitionId": "{{WORKFLOW_DEFINITION_ID}}",
                          "context": {
                            "requestor": appVars.currentUser.email,
                            "amount": pageVars.formData.amount,
                            "description": pageVars.formData.description
                          }
                        }
                ──► [If: status == 201]
                      ├─ True ──► [Toast: "Workflow started"]
                      └─ False ──► [Toast: "Error: " + outputs.error]
```

## Error Catalog

| Error | Context | Root Cause | Fix |
|-------|---------|------------|-----|
| `CORS error` | REST integration | API doesn't allow Build Apps origin | Use BTP Destination (proxy) instead of direct URL |
| `401 Unauthorized` | Data fetch | Auth token expired or misconfigured | Check destination auth config; refresh token |
| `404 Not Found` | OData call | Wrong entity set or service URL | Verify OData service URL in destination |
| `Network Error` | Preview/runtime | BTP destination unreachable | Check destination status in BTP cockpit |
| `Formula error` | Visual formula | Type mismatch or null value | Add null checks: `IF(IS_NULLY(x), default, x)` |
| Build failed | iOS/Android build | Missing certificates or provisioning | Upload valid signing certificates in Build Service |
| `Blank page` | Deployed app | Missing HTML5 app router config | Configure `xs-app.json` routes correctly |
| `Data variable empty` | Page load | Data fetch timing issue | Add delay or use "Data variable initialized" event |

## Performance Tips

1. **Minimize data variables per page** — Each triggers an API call on page load; use pagination
2. **Client-side filtering** — For small datasets (<500 records), fetch once and filter with `SELECT()` formula
3. **Server-side filtering** — For large datasets, pass OData `$filter` parameters
4. **Image optimization** — Use compressed images; lazy-load off-screen images
5. **Reduce page complexity** — Keep components under 50 per page; use subpages for complex UIs
6. **Cache with app variables** — Store reference data (dropdown options) in app variables, not per-page
7. **Avoid deep nesting** — Deeply nested containers slow rendering; flatten where possible

## Gotchas

- **Not a code platform**: Build Apps generates runtime code — you cannot directly edit JavaScript/HTML
- **BTP Destination required**: Direct REST calls hit CORS issues; always use BTP destination as proxy
- **Mobile build queue**: iOS/Android builds go through a shared queue; expect 10-30 min wait times
- **Version control**: No native Git integration; use project export/import for backup
- **Formula limits**: Complex formulas with deep nesting can become unreadable — break into page variables
- **Data variable refresh**: Default polling interval is 5 seconds; disable auto-refresh for static data
