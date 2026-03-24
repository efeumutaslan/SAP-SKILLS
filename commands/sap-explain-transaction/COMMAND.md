---
name: sap-explain-transaction
description: Explain an SAP transaction code — what it does, when to use it, related transactions, and modern API/Fiori alternatives for S/4HANA.
allowed-tools: Read Grep WebSearch
---

# /sap-explain-transaction [TCODE]

Explain an SAP transaction code and suggest modern alternatives.

## Arguments
- `TCODE` (required): SAP transaction code, e.g., `MM03`, `VA01`, `SE38`, `PFCG`

## Output Format

```markdown
## Transaction: {{TCODE}} — {{Full Name}}

### What It Does
{{Clear explanation of the transaction's purpose and when to use it}}

### Module & Area
- **Module:** {{e.g., MM, SD, FI, BASIS}}
- **Component:** {{e.g., Materials Management — Material Master}}
- **Authorization Object:** {{e.g., M_MATE_BUK}}

### Key Screens / Tabs
{{List main screens and their purpose}}

### Related Transactions
| TCode | Name | Relationship |
|-------|------|-------------|
| {{related}} | {{name}} | {{how it relates}} |

### Modern Alternatives (S/4HANA)
| Alternative | Type | When to Use |
|------------|------|-------------|
| {{Fiori app ID}} | Fiori App | {{scenario}} |
| {{API name}} | OData API | {{scenario}} |
| {{RAP BO}} | RAP BO | {{scenario}} |

### API Replacement
If automating this transaction, use:
- **OData V4:** `{{API endpoint}}`
- **BAPI:** `{{BAPI name}}`
- **RAP:** `{{RAP entity}}`

### Tips
- {{Practical usage tips}}
- {{Common mistakes to avoid}}
```

## Common Transaction Knowledge Base

### Materials Management
- `MM01/02/03` → Material Master Create/Change/Display → API_PRODUCT_SRV
- `ME21N/22N/23N` → Purchase Order Create/Change/Display → API_PURCHASEORDER_PROCESS_SRV
- `MIGO` → Goods Movement → API_MATERIAL_DOCUMENT_SRV
- `MIRO` → Invoice Verification → API_SUPPLIERINVOICE_PROCESS_SRV

### Sales & Distribution
- `VA01/02/03` → Sales Order Create/Change/Display → API_SALES_ORDER_SRV
- `VL01N/02N` → Delivery Create/Change → API_OUTBOUND_DELIVERY_SRV
- `VF01/02/03` → Billing Document → API_BILLING_DOCUMENT_SRV

### Finance
- `FB01/50` → Post Document → API_JOURNALENTRY_POST
- `F-28/32` → Incoming/Clearing Payment → API_PAYMENT
- `FBL1N/3N/5N` → Vendor/GL/Customer Line Items → CDS: I_JournalEntry

### Basis / Admin
- `SE38` → ABAP Editor → ADT (Eclipse)
- `SE80` → Object Navigator → ADT (Eclipse)
- `PFCG` → Role Maintenance → Fiori: Maintain Business Roles
- `SU01` → User Maintenance → Fiori: Maintain Business Users
- `SM37` → Job Overview → Fiori: Application Jobs
- `ST22` → ABAP Dump Analysis → ADT: Feed Reader (ABAP Dumps)

## Execution Steps

1. Parse transaction code from argument
2. Look up in knowledge base or search for details
3. Find modern Fiori/API alternatives
4. Generate structured explanation
5. Include practical tips and common authorization requirements
