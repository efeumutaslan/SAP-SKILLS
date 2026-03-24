---
name: sap-s4hana-extensibility
description: |
  SAP S/4HANA extensibility and Clean Core development skill. Use when: extending S/4HANA
  with custom logic, implementing BAdIs, creating Custom Business Objects, working with
  released APIs, checking Clean Core compliance, building side-by-side or in-app extensions,
  using Key User extensibility tools, extending CDS views, extending RAP business objects,
  working with the 3-tier/4-level model, wrapping classic APIs for ABAP Cloud consumption,
  or planning S/4HANA extension architecture. Covers Public Cloud, Private Cloud, and On-Premise.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  s4hana_version: "2025+"
  last_verified: "2026-03-23"
---

# SAP S/4HANA Extensibility & Clean Core

## Related Skills
- `sap-rap-comprehensive` — RAP business object development and extension
- `sap-security-authorization` — Authorization for extensions
- `sap-migration-modernization` — Migrating classic code to ABAP Cloud

## Quick Start

**Choose your extensibility approach:**

| Need | Approach | Who |
|------|----------|-----|
| Add field to standard object | Key-User: Custom Fields app (F1481) | Consultant |
| Add validation/defaulting logic | Key-User: Custom Logic app (F6957) or Developer: Cloud BAdI in ADT | Consultant/Developer |
| New standalone business object | Key-User: Custom Business Objects app or Developer: RAP BO | Consultant/Developer |
| Complex app on BTP | Side-by-Side: CAP/Fiori on BTP via released APIs | Developer |
| Extend CDS view with custom field | Developer: `EXTEND VIEW ENTITY` in ADT | Developer |
| Extend RAP BO behavior | Developer: `extend behavior for` in ADT | Developer |

**Check if your API is released:**
```
ADT → Project Explorer → Released Objects → filter by object type
or: api.sap.com → Package S4HANACloudBADI (for Cloud BAdIs)
```

## Core Concepts

### Clean Core 4-Level Model

| Level | Name | What's Allowed | Upgrade Safety |
|-------|------|----------------|----------------|
| **A** | Fully Compliant | Released APIs only (C0/C1/C2), ABAP Cloud | Fully safe |
| **B** | Compliant | Level A + classic APIs (BAPIs, standard BAdIs) | Generally safe |
| **C** | Partially Compliant | SAP internal objects, unrestricted ABAP | Risk of breakage |
| **D** | Non-Compliant | Modifications, direct table writes, implicit enhancements | High risk |

**Target: Level A for all new development.**

### Extensibility Availability Matrix

| Type | Public Cloud | Private Cloud | On-Premise |
|------|-------------|---------------|------------|
| Key-User (In-App) | Yes | Yes | Yes (limited) |
| Developer (ABAP Cloud) | Yes | Yes | Yes (2022+) |
| Side-by-Side (BTP) | Yes | Yes | Yes |
| Classic ABAP (unrestricted) | **No** | Yes | Yes |
| SAP GUI (SE80, SE38...) | **No** | Yes | Yes |
| Code modifications | **No** | **No** | Yes (discouraged) |

### Release Contracts

| Contract | Name | Use |
|----------|------|-----|
| **C0** | Extensibility | CDS extend, BAdI implement |
| **C1** | System-Internal | On-stack consumption (classes, interfaces, CDS) |
| **C2** | Remote API | External consumption (OData, SOAP, RFC) |
| **C3** | Key-User Apps | Custom Fields, Custom Logic apps |

Check in ADT: Right-click object → Properties → API State.

## Common Patterns

### Pattern 1: Implement a Cloud BAdI (Developer Extensibility)

```abap
" Example: Validate Purchase Requisition
CLASS zcl_check_purch_req DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_badi_interface.
    INTERFACES if_mm_pur_s4_pr_check.
ENDCLASS.

CLASS zcl_check_purch_req IMPLEMENTATION.
  METHOD if_mm_pur_s4_pr_check~check.
    LOOP AT purchaserequisitionitem ASSIGNING FIELD-SYMBOL(<item>).
      IF <item>-PurchaseRequisitionType = 'NB'
         AND <item>-PurchasingGroup IS INITIAL.
        APPEND VALUE #(
          %tky = <item>-%tky
          %msg = new_message(
            id       = 'ZMM_PR'
            number   = '001'
            severity = if_abap_behv_message=>severity-warning )
        ) TO reported-purchaserequisitionitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

### Pattern 2: Extend a CDS View Entity

```cds
" Add custom field to a released SAP CDS view
extend view entity I_PurchaseOrderItemAPI01
  with {
    pur_doc_item.YY1_CustomField as CustomField
  }
```

With association:
```cds
extend view entity I_SalesOrder
  with association [0..*] to ZI_CustomData as _CustomData
    on $projection.SalesOrder = _CustomData.SalesOrder
  {
    _CustomData
  }
```
**Prerequisite:** Target CDS must have `@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]`.

### Pattern 3: Extend RAP BO Behavior

```cds
extend behavior for I_PurchaseOrderTP {
  determination SetCustomDefault on modify { field PurchaseOrderType; }
  validation ValidateCustomField on save { field YY1_CustomField; }
}
```

### Pattern 4: Tier 2 Wrapper (Classic API → ABAP Cloud)

When a released API doesn't exist for a needed classic function:

```abap
" Step 1: Interface (released with C1)
INTERFACE zif_po_create PUBLIC.
  METHODS create_po
    IMPORTING is_header TYPE bapimepoheader
    EXPORTING es_result TYPE bapimepoheaderx
    RAISING   zcx_po_error.
ENDINTERFACE.

" Step 2: Factory (released with C1)
CLASS zcl_po_create_factory DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO zif_po_create.
ENDCLASS.

" Step 3: Implementation (NOT released — classic ABAP, calls BAPI)
CLASS zcl_po_create_impl DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_po_create.
ENDCLASS.

CLASS zcl_po_create_impl IMPLEMENTATION.
  METHOD zif_po_create~create_po.
    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING poheader = is_header
      IMPORTING expheader = es_result.
    " ... error handling ...
  ENDMETHOD.
ENDCLASS.
```

**Key:** Release the interface and factory with C1. The implementation stays unreleased (Tier 2).

### Pattern 5: Custom Business Object (Key-User)

1. Open Fiori app **Custom Business Objects**
2. Name: `YY1_ProjectTracker`, fields: ProjectID, Name, Status, StartDate
3. Check **UI Generation** for auto-generated Fiori maintenance app
4. Add logic: After Modification → Determination (auto-set defaults)
5. Add logic: Before Save → Validation (mandatory field checks)
6. Publish → OData API auto-generated at `/sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/`

## Error Catalog

| Error | Cause | Fix |
|-------|-------|-----|
| "Not released for ABAP Cloud" | Calling unreleased API from Tier 1 | Find released successor or create Tier 2 wrapper |
| "Object type not available" | Using classic types (FM, include) in ABAP Cloud | Refactor to class-based approach |
| "View entity does not allow extensions" | Missing `@AbapCatalog.viewEnhancementCategory` | CDS view is not extensible; check api.sap.com |
| "BAdI implementation will not be called" | Filter mismatch or not activated | Check enhancement implementation activation and filter values |
| "No released successor found" | Classic API has no cloud equivalent | Check nominated APIs; create Tier 2 wrapper; log SAP influence request |
| "Enhancement implementation exists" | Duplicate name | Use unique Z-namespaced names |
| "Transport failed" for CBO | Not assigned to transport request | Check Extensibility Inventory app |
| ATC: "Incompatible change detected" | Breaking change in custom code | Review ATC findings; use Quick Fix in ADT |
| "Maximum fields exceeded" on CBO | CBO field count limit reached | Split into header/item structure |
| "Association target not published" | Target CBO not yet published | Publish target CBO first |

## Performance Tips

- Run **ATC cloud readiness checks** early and often (variant: `ABAP_CLOUD_READINESS`)
- Keep wrapper classes thin — only translate parameters, don't add business logic
- Use `EXTEND VIEW ENTITY` (new syntax), not deprecated `EXTEND VIEW`
- Prefer CBO for simple master data; use RAP BO for complex scenarios
- Side-by-side extensions: cache API responses to reduce round-trips to S/4HANA

## Bundled Resources

Read these files on demand for deeper guidance:

| File | When to Read |
|------|-------------|
| `references/clean-core-levels.md` | Deep dive on 4-level model with migration guidance |
| `references/cloud-badi-catalog.md` | Finding and implementing released Cloud BAdIs |
| `references/tier2-wrapper-guide.md` | Step-by-step wrapper pattern with full examples |
| `references/cbo-guide.md` | Custom Business Objects creation and integration |
| `references/cds-extension-patterns.md` | All CDS view extension patterns |
| `templates/badi-implementation.abap` | Cloud BAdI implementation template |
| `templates/tier2-wrapper.abap` | Tier 2 wrapper class template |
| `templates/cds-extend.cds` | CDS view extension template |

## Source Documentation

- [SAP Extensibility Explorer](https://extensibilityexplorer.cfapps.eu10.hana.ondemand.com)
- [SAP API Business Hub — Cloud BAdIs](https://api.sap.com/package/S4HANACloudBADI)
- [GitHub: SAP ATC Cloud Readiness Checks](https://github.com/SAP/abap-atc-cr-cv-s4hc)
- [GitHub: RAP Tier 2 Wrapper Workshop](https://github.com/SAP-samples/abap-platform-rap640)
- [GitHub: RAP Developer Extensibility](https://github.com/SAP-samples/abap-platform-rap630)
- [SAP Help: ABAP Cloud Language Version](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/abenabap_versions_and_apis.htm)
