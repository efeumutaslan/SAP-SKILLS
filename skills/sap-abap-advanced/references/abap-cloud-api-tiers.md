# ABAP Cloud API Tiers & Release Contracts

## Tier Model

```
┌─────────────────────────────────────────────────┐
│                  Tier 1                          │
│          ABAP for Cloud Development              │
│  ┌─────────────────────────────────────────┐    │
│  │  Only released APIs (C1 contract)       │    │
│  │  CDS: I_*, C_* views                   │    │
│  │  Classes: Released via ADT              │    │
│  │  BAdIs: Released enhancement spots      │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  WHERE: BTP Steampunk, S/4HANA Cloud Public      │
├─────────────────────────────────────────────────┤
│                  Tier 2                          │
│             Standard ABAP                        │
│  ┌─────────────────────────────────────────┐    │
│  │  All APIs (released + non-released)     │    │
│  │  Full ABAP language scope               │    │
│  │  Custom wrappers for Tier 1 consumers   │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  WHERE: S/4HANA Private Cloud, On-Premise        │
├─────────────────────────────────────────────────┤
│                  Tier 3                          │
│           Key User Extensibility                 │
│  ┌─────────────────────────────────────────┐    │
│  │  No code — configuration only           │    │
│  │  Custom fields, custom logic (BRF+)     │    │
│  │  Custom Business Objects                │    │
│  └─────────────────────────────────────────┘    │
│                                                  │
│  WHERE: S/4HANA Cloud Public (Key User apps)     │
└─────────────────────────────────────────────────┘
```

## Release Contracts

| Contract | Stability | Who Can Use | Example |
|----------|-----------|-------------|---------|
| **C1 — Released** | Backward-compatible across releases | Tier 1 (Cloud) | `CL_BCS_MAIL_MESSAGE`, `I_BusinessPartner` |
| **C0 — Not Released** | Can change without notice | Tier 2 only | Internal SAP classes, legacy FMs |
| **C2 — Deprecated** | Will be removed in future release | None (migrate away) | `REUSE_ALV_GRID_DISPLAY` |

## How to Check Release Status

### In ADT (Eclipse)
1. Open the ABAP element (class, interface, CDS view)
2. Properties view → General tab → **API State**
3. Look for: `Released` / `Not Released` / `Deprecated`

### Via Cloudification Repository (api.sap.com)
1. Go to `api.sap.com` → ABAP Cloud section
2. Search for the object name
3. Check availability and successor information

### Programmatically
```abap
" Check if an object is released
DATA(lo_checker) = cl_abap_comp_check=>get_instance( ).
DATA(lv_released) = lo_checker->is_released(
  iv_object_type = 'CLAS'
  iv_object_name = 'CL_BCS_MAIL_MESSAGE'
).
```

## Common Released API Categories

### Communication
| Released API | Purpose | Replaces |
|-------------|---------|----------|
| `CL_BCS_MAIL_MESSAGE` | Send emails | `SO_NEW_DOCUMENT_SEND_API1` |
| `IF_HTTP_SERVICE_EXTENSION` | HTTP service handler | `IF_HTTP_EXTENSION` |
| `CL_ABAP_PARALLEL` | Parallel processing | `CALL FUNCTION ... STARTING NEW TASK` |

### Data Access
| Released API | Purpose | Replaces |
|-------------|---------|----------|
| `I_BusinessPartner` | Business Partner CDS | `KNA1`, `LFA1`, `BUT000` |
| `I_SalesOrder` | Sales Order CDS | `VBAK`, `VBAP` |
| `I_PurchaseOrder` | Purchase Order CDS | `EKKO`, `EKPO` |
| `I_JournalEntry` | Accounting CDS | `BSEG`, `ACDOCA` |
| `I_Product` | Material CDS | `MARA`, `MAKT` |

### Utilities
| Released API | Purpose | Replaces |
|-------------|---------|----------|
| `CL_ABAP_CONTEXT_INFO` | System info (date, user, etc.) | `SY-DATUM`, `SY-UNAME` |
| `CL_ABAP_RANDOM_*` | Random number generation | `QF05_RANDOM_INTEGER` |
| `XCO_CP_*` | Extension Components (XCO) library | Various utility FMs |
