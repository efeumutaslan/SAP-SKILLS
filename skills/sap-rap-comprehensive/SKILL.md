---
name: sap-rap-comprehensive
description: |
  SAP RAP (RESTful Application Programming Model) comprehensive development skill. Use when:
  creating RAP business objects, writing behavior definitions (BDEF), modeling CDS view entities,
  implementing validations/determinations/actions, handling draft-enabled scenarios, writing
  EML (Entity Manipulation Language), implementing authorization checks, creating service
  bindings, writing RAP unit tests with test doubles, working with managed/unmanaged
  implementation types, configuring side effects, feature control, business events,
  late numbering, or extending standard SAP RAP BOs. Covers BTP, S/4HANA Cloud, and On-Premise.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
  abap_platform: "2022+"
---

# SAP RAP — RESTful Application Programming Model

## Related Skills
- `sap-s4hana-extensibility` — Extending standard SAP RAP BOs
- `sap-security-authorization` — RAP authorization patterns
- `sap-testing-quality` — RAP test doubles in depth

## Quick Start

**RAP BO in 5 artifacts:**
```
1. Database Table     → ZTAB_TRAVEL
2. CDS View Entity    → ZI_Travel (interface, root)
3. Behavior Definition → ZI_Travel (managed, draft)
4. Behavior Impl.     → ZBP_I_Travel (handler + saver)
5. Service Definition  → ZSD_Travel → Service Binding (V4)
```

**Minimum BDEF (managed with draft):**
```cds
managed implementation in class zbp_i_travel unique;
strict ( 2 );
with draft;

define behavior for ZI_Travel alias Travel
persistent table ztab_travel
draft table zdraft_travel
etag master LocalLastChangedAt
lock master total etag LastChangedAt
authorization master ( global, instance )
{
  field ( readonly ) TravelUUID;
  field ( mandatory ) AgencyID, CustomerID;

  create; update; delete;

  determination SetStatusNew on modify { create; }
  validation ValidateDates on save { field BeginDate, EndDate; }
  action ( features : instance ) AcceptTravel result [1] $self;

  draft action Resume;
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft determine action Prepare;

  mapping for ztab_travel corresponding;
}
```

## Core Concepts

### RAP Architecture Layers

```
┌─ Service Layer ──────────────────────────────┐
│  Service Definition → Service Binding (V2/V4) │
├─ BO Projection Layer ────────────────────────┤
│  CDS Projection View (C_*) + Projection BDEF  │
├─ BO Interface Layer ─────────────────────────┤
│  CDS View Entity (I_*) + Behavior Definition   │
│  + Behavior Implementation (Handler/Saver)     │
├─ Data Layer ─────────────────────────────────┤
│  Database Tables / CDS Abstract Entities       │
└──────────────────────────────────────────────┘
```

### Implementation Types

| Type | When to Use | Key Difference |
|------|------------|----------------|
| **Managed** | New greenfield development | Framework handles CRUD + persistence |
| **Unmanaged** | Wrapping legacy (BAPIs, FMs) | Developer handles all persistence |
| **Managed + Unmanaged Save** | Managed CRUD but custom save | Framework CRUD, you handle DB write |
| **Managed + Additional Save** | Managed save + extra side-effects | Framework saves, you do extra work |

### CDS View Entity — Root with Child

```cds
@AccessControl.authorizationCheck: #CHECK
define root view entity ZI_Travel
  as select from ztab_travel
  composition [0..*] of ZI_Booking as _Booking
{
  key travel_uuid       as TravelUUID,
      travel_id         as TravelID,
      agency_id         as AgencyID,
      customer_id       as CustomerID,
      begin_date        as BeginDate,
      end_date          as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price       as TotalPrice,
      currency_code     as CurrencyCode,
      overall_status    as OverallStatus,
      @Semantics.user.createdBy: true
      created_by        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at        as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by   as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at   as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Booking
}
```

## Common Patterns

### Pattern 1: Validation (on save)

```abap
METHOD validateDates.
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( BeginDate EndDate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  LOOP AT lt_travels INTO DATA(ls_travel).
    IF ls_travel-BeginDate > ls_travel-EndDate.
      APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
      APPEND VALUE #( %tky = ls_travel-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Begin date must be before end date' )
        %element-BeginDate = if_abap_behv=>mk-on
        %element-EndDate   = if_abap_behv=>mk-on
      ) TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
```

### Pattern 2: Determination (on modify)

```abap
METHOD setStatusNew.
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  MODIFY ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR travel IN lt_travels
      WHERE ( OverallStatus IS INITIAL )
      ( %tky = travel-%tky  OverallStatus = 'O' ) ).  " Open
ENDMETHOD.
```

### Pattern 3: Action with Result

```abap
METHOD acceptTravel.
  MODIFY ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( OverallStatus )
    WITH VALUE #( FOR key IN keys
      ( %tky = key-%tky  OverallStatus = 'A' ) ).  " Accepted

  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  result = VALUE #( FOR travel IN lt_travels
    ( %tky = travel-%tky  %param = travel ) ).
ENDMETHOD.
```

### Pattern 4: Instance Feature Control

```abap
METHOD get_instance_features.
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  result = VALUE #( FOR travel IN lt_travels
    ( %tky = travel-%tky
      %action-AcceptTravel = COND #(
        WHEN travel-OverallStatus = 'A'
        THEN if_abap_behv=>fc-o-disabled    " Already accepted
        ELSE if_abap_behv=>fc-o-enabled )
      %action-RejectTravel = COND #(
        WHEN travel-OverallStatus = 'X'
        THEN if_abap_behv=>fc-o-disabled    " Already rejected
        ELSE if_abap_behv=>fc-o-enabled )
    ) ).
ENDMETHOD.
```

### Pattern 5: Authorization (Global + Instance)

```abap
" Global authorization: Can user create at all?
METHOD get_global_authorizations.
  IF requested_authorizations-%create = if_abap_behv=>mk-on.
    AUTHORITY-CHECK OBJECT 'Z_TRAVEL' ID 'ACTVT' FIELD '01'.
    result-%create = COND #(
      WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).
  ENDIF.
ENDMETHOD.

" Instance authorization: Can user update THIS travel?
METHOD get_instance_authorizations.
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel FIELDS ( AgencyID ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  LOOP AT lt_travels INTO DATA(ls_travel).
    AUTHORITY-CHECK OBJECT 'Z_TRAVEL'
      ID 'ACTVT' FIELD '02'
      ID 'Z_AGNCY' FIELD ls_travel-AgencyID.
    DATA(lv_update) = COND #(
      WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).

    APPEND VALUE #( %tky = ls_travel-%tky
      %update = lv_update
      %action-AcceptTravel = lv_update
    ) TO result.
  ENDLOOP.
ENDMETHOD.
```

### Pattern 6: EML (Entity Manipulation Language)

```abap
" Create
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate )
  WITH VALUE #( (
    %cid       = 'CID_1'
    AgencyID   = '70001'
    CustomerID = '100000'
    BeginDate  = cl_abap_context_info=>get_system_date( )
    EndDate    = cl_abap_context_info=>get_system_date( ) + 14
  ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

" Read
READ ENTITIES OF zi_travel
  ENTITY Travel
  ALL FIELDS
  WITH VALUE #( ( TravelUUID = lv_uuid ) )
  RESULT DATA(lt_result).

" Commit
COMMIT ENTITIES
  RESPONSE OF zi_travel
  FAILED DATA(ls_commit_failed)
  REPORTED DATA(ls_commit_reported).
```

### Pattern 7: Draft Handling Flow

```
[New]
  → Edit → [Draft created in draft table]
    → Modify fields (auto-saved to draft table)
      → Prepare (runs validations on draft)
        → Activate (moves draft → active table, runs on-save validations)

[Existing Active]
  → Edit → [Copy to draft table, lock active]
    → Modify → Prepare → Activate

[Discard] → Delete draft, unlock active
[Resume] → Continue editing existing draft
```

**Draft table structure:** Same as active table + admin fields (`%is_draft`, `draftentityoperationcode`, etc.)

## Error Catalog

| Error | Cause | Fix |
|-------|-------|-----|
| "Entity not modifiable" | Missing `update` in BDEF | Add `update;` to behavior definition |
| "Draft table does not exist" | Draft table not created | Create DDIC table matching draft table name in BDEF |
| CDS activation "composition invalid" | Child not defined as `root` or composition mismatch | Child must NOT be root; check `composition [0..*] of` syntax |
| "Determination not triggered" | Wrong trigger event (on modify vs on save) | Verify trigger: `on modify { create; }` vs `on save { field X; }` |
| "Authorization check failed" | Missing AUTHORITY-CHECK or wrong object | Implement `get_global_authorizations` / `get_instance_authorizations` |
| BDEF activation "strict mode" | Using deprecated syntax in `strict ( 2 )` | Use current syntax; check ADT error message for guidance |
| "%cid not found in mapped" | Create-by-association without matching %cid_ref | Ensure parent %cid matches child %cid_ref in EML |
| "Lock conflict" on edit | Another user has active draft | Check draft table for existing draft; use Resume if same user |
| "Feature control not working" | Method signature mismatch | Use exact parameter types from handler class interface |
| "etag mismatch" | Stale data (concurrent modification) | Reload data and retry; check etag field definition |

## Performance Tips

- Use `IN LOCAL MODE` in handler methods to skip authorization re-checks
- Read only needed fields: `FIELDS ( Field1 Field2 )` not `ALL FIELDS`
- Avoid N+1 queries: batch-read entities, don't loop-and-read
- Use `%control` to detect which fields were actually sent by the client
- Keep validations focused: one validation per business rule
- Use `on modify` determinations for immediate feedback, `on save` for expensive checks

## BTP vs S/4HANA Differences

| Aspect | BTP ABAP Environment | S/4HANA Cloud/On-Prem |
|--------|---------------------|----------------------|
| strict mode | `strict ( 2 )` required | `strict ( 1 )` or none |
| Available APIs | Only released (C1/C2) | All (on-prem), released (cloud) |
| ABAP version | ABAP Cloud only | Cloud or Classic |
| Service binding | OData V4 default | V2 and V4 available |
| Draft | Standard | Standard |
| Extend SAP BO | Via released extension points | Full access (on-prem) |

## Bundled Resources

| File | When to Read |
|------|-------------|
| `references/rap-complete-guide.md` | Full RAP reference with all patterns |
| `references/bdef-syntax-reference.md` | Complete BDEF syntax reference |
| `references/eml-cheatsheet.md` | EML statement quick reference |
| `templates/managed-bo.cds` | Complete managed RAP BO template |
| `templates/handler-class.abap` | Handler class implementation template |
| `templates/test-class.abap` | RAP unit test template with CL_BOTD |

## Source Documentation

- [SAP Help: RAP](https://help.sap.com/docs/abap-cloud/abap-rap/restful-abap-programming-model)
- [GitHub: SAP ABAP Cheat Sheets — RAP](https://github.com/SAP-samples/abap-cheat-sheets)
- [GitHub: RAP Generator](https://github.com/SAP-samples/cloud-abap-rap)
- [SAP RAP Developer Guide](https://help.sap.com/docs/btp/sap-abap-restful-application-programming-model)
- [GitHub: RAP Workshops (RAP100-640)](https://github.com/SAP-samples/abap-platform-rap100)
