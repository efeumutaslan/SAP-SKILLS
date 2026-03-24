---
name: sap-migration
description: >
  SAP S/4HANA migration and data conversion skill. Use when migrating data with LTMC/Migration
  Cockpit, planning cutover, cleansing data, or converting from ECC to S/4HANA. If the user
  mentions S/4HANA migration, LTMC, data migration, brownfield/greenfield conversion, or
  cutover planning, use this skill.
disable-model-invocation: true
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.1.0"
  last_verified: "2026-03-25"
---

# SAP Migration — Data Migration & System Conversion

## Related Skills
- `sap-s4hana-extensibility` — Custom objects to migrate in S/4HANA
- `sap-testing-quality` — Migration testing and data validation
- `sap-cloud-alm` — Migration project management and tracking
- `sap-abap-advanced` — Classic ABAP → ABAP Cloud code migration
- `sap-devops-cicd` — Transport management during migration cutover

## Quick Start

**Choose your migration scenario:**

| Scenario | Approach | Key Tool |
|----------|----------|----------|
| **New Implementation (Greenfield)** | Fresh S/4HANA, migrate master/transactional data | Migration Cockpit (LTMC) |
| **System Conversion (Brownfield)** | Convert existing ECC to S/4HANA in-place | SUM (Software Update Manager) |
| **Selective Data Transition** | Mix of new + migrated data | SAP Data Services / SNP CrystalBridge |
| **Cloud Migration** | On-premise → S/4HANA Cloud | Migration Cockpit Cloud |

**Migration Cockpit Quick Start:**
1. Transaction `LTMC` → Create Migration Project
2. Select Migration Object (e.g., "General Ledger Account")
3. Download XML template → Fill with source data
4. Upload → Validate → Simulate → Execute

## Core Concepts

### Migration Phases
```
Assessment ──► Preparation ──► Realization ──► Testing ──► Cutover ──► Hypercare
    │              │              │              │           │            │
 Scope &        Data          Build &        Validate     Go-live     Monitor
 Mapping       Cleansing     Configure       & UAT       Execute     & Fix
```

### Migration Tools Landscape
| Tool | Use Case | Data Volume | Complexity |
|------|----------|-------------|------------|
| **LTMC (Migration Cockpit)** | Standard objects, file upload | Medium | Low |
| **LTMOM (Migration Object Modeler)** | Custom migration objects | Medium | Medium |
| **SAP Data Services** | Complex ETL, large volumes | High | High |
| **LSMW** | Legacy (ECC), batch input/IDoc/BAPI | Medium | Medium |
| **Custom ABAP Programs** | Non-standard scenarios | Any | High |
| **SAP Signavio (Process)** | Process migration planning | N/A | Medium |
| **SUM** | System conversion (brownfield) | All | Very High |

### Standard Migration Objects (LTMC)
| Domain | Key Objects |
|--------|------------|
| **Finance** | GL Account, Cost Center, Profit Center, Customer, Vendor, Open Items |
| **Materials** | Material Master, BOM, Routing, Batch, Serial Number |
| **Sales** | Sales Order, Pricing, Customer-Material Info Record |
| **Procurement** | Purchase Order, Source List, Quota Arrangement, Contract |
| **Plant Maintenance** | Equipment, Functional Location, Maintenance Plan |
| **HR/HCM** | Employee Master, Org Structure, Time Data, Payroll Results |
| **Asset Accounting** | Asset Master, Asset Values, Depreciation Areas |

### Data Migration Architecture
```
Source System ──► Extract ──► Transform ──► Load ──► Validate
   │                │            │           │          │
  ECC/Legacy    SAP DS /     Mapping &    LTMC /    Reconcile
  Flat files    Custom ABAP  Cleansing    BAPI      Reports
  3rd party     RFC/DB       Rules        Staging
```

## Common Patterns

### Pattern 1: Migration Cockpit — File-Based Migration

```xml
<!-- Template structure for Material Master migration -->
<!-- Download from LTMC, fill, re-upload -->

<MigrationObject name="Material">
  <HeaderData>
    <MATNR>MAT-001</MATNR>
    <MAKTX>Laptop Computer 15 inch</MAKTX>
    <MTART>FERT</MTART>           <!-- Material Type -->
    <MBRSH>M</MBRSH>              <!-- Industry Sector -->
    <MEINS>EA</MEINS>             <!-- Base UoM -->
    <MATKL>001</MATKL>            <!-- Material Group -->
    <SPART>01</SPART>             <!-- Division -->
    <BISMT>OLD-MAT-001</BISMT>    <!-- Old Material Number -->
  </HeaderData>
  <PlantData>
    <WERKS>1010</WERKS>
    <EKGRP>001</EKGRP>            <!-- Purchasing Group -->
    <DISMM>PD</DISMM>             <!-- MRP Type -->
    <DISPO>001</DISPO>            <!-- MRP Controller -->
    <PLIFZ>5</PLIFZ>              <!-- Planned Delivery Time -->
  </PlantData>
  <StorageLocationData>
    <WERKS>1010</WERKS>
    <LGORT>0001</LGORT>
  </StorageLocationData>
  <SalesData>
    <VKORG>1010</VKORG>
    <VTWEG>10</VTWEG>
    <SPART>01</SPART>
  </SalesData>
</MigrationObject>
```

### Pattern 2: Custom Migration Object (LTMOM)

```abap
" Step 1: Create custom migration object in LTMOM
" Step 2: Implement BAPI/staging table approach

" Migration class for custom object
CLASS zcl_migrate_custom_obj DEFINITION.
  PUBLIC SECTION.
    METHODS:
      validate_data
        IMPORTING it_data TYPE ztab_migration_data
        RETURNING VALUE(rt_errors) TYPE bapiret2_t,
      execute_migration
        IMPORTING it_data TYPE ztab_migration_data
        RETURNING VALUE(rt_results) TYPE ztab_migration_result.
ENDCLASS.

CLASS zcl_migrate_custom_obj IMPLEMENTATION.
  METHOD validate_data.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<data>).
      " Mandatory field checks
      IF <data>-field1 IS INITIAL.
        APPEND VALUE #(
          type = 'E'
          id = 'ZMIG'
          number = '001'
          message_v1 = <data>-key_field
          message = |Field1 is mandatory for { <data>-key_field }|
        ) TO rt_errors.
      ENDIF.

      " Value mapping check
      IF NOT check_value_mapping( <data>-old_value ).
        APPEND VALUE #(
          type = 'E'
          id = 'ZMIG'
          number = '002'
          message = |No mapping for value { <data>-old_value }|
        ) TO rt_errors.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD execute_migration.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<data>).
      TRY.
          " Call BAPI or direct insert
          CALL FUNCTION 'BAPI_CUSTOM_CREATE'
            EXPORTING
              is_header = map_to_target( <data> )
            IMPORTING
              ev_number = DATA(lv_number)
            TABLES
              return   = DATA(lt_return).

          READ TABLE lt_return WITH KEY type = 'E' TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            APPEND VALUE #( key = <data>-key_field status = 'E' messages = lt_return ) TO rt_results.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING wait = abap_true.
            APPEND VALUE #( key = <data>-key_field status = 'S' new_number = lv_number ) TO rt_results.
          ENDIF.
        CATCH cx_root INTO DATA(lx_error).
          APPEND VALUE #( key = <data>-key_field status = 'E'
                          message = lx_error->get_text( ) ) TO rt_results.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

### Pattern 3: Value Mapping Table

```abap
" Value mapping for legacy → S/4HANA conversion
" Store in custom table ZTAB_VALUE_MAP

TYPES: BEGIN OF ty_value_map,
         object_type  TYPE char20,   " e.g., MATERIAL_TYPE
         source_value TYPE char50,   " Legacy value
         target_value TYPE char50,   " S/4HANA value
         valid_from   TYPE datum,
         valid_to     TYPE datum,
       END OF ty_value_map.

" Usage in migration
METHOD map_value.
  SELECT SINGLE target_value FROM ztab_value_map
    WHERE object_type  = @iv_object_type
      AND source_value = @iv_source_value
      AND valid_from  <= @sy-datum
      AND valid_to    >= @sy-datum
    INTO @rv_target_value.
  IF sy-subrc <> 0.
    " No mapping found — log warning and use source value
    log_warning( |No mapping: { iv_object_type }/{ iv_source_value }| ).
    rv_target_value = iv_source_value.
  ENDIF.
ENDMETHOD.
```

### Pattern 4: Data Quality Report

```sql
-- Pre-migration data quality checks (run on source ECC)

-- Duplicate customer check
SELECT kunnr, name1, COUNT(*) AS cnt
  FROM kna1
  GROUP BY kunnr, name1
  HAVING COUNT(*) > 1;

-- Orphan records (sales orders without customer)
SELECT vbak~vbeln, vbak~kunnr
  FROM vbak
  LEFT OUTER JOIN kna1 ON vbak~kunnr = kna1~kunnr
  WHERE kna1~kunnr IS NULL;

-- Material without valid UoM
SELECT matnr, meins
  FROM mara
  WHERE meins NOT IN (SELECT msehi FROM t006);

-- Open items with missing clearing info
SELECT bukrs, belnr, gjahr, buzei, dmbtr
  FROM bsid  -- Open customer items
  WHERE augdt IS NULL
    AND budat < '20200101';  -- Very old open items

-- Vendor/Customer with incomplete address
SELECT lifnr, name1, stras, ort01, pstlz, land1
  FROM lfa1
  WHERE stras IS INITIAL OR ort01 IS INITIAL OR land1 IS INITIAL;
```

### Pattern 5: Reconciliation Report

```abap
" Post-migration reconciliation
REPORT z_migration_reconcile.

" Compare source vs target record counts
TYPES: BEGIN OF ty_recon,
         object_name  TYPE char30,
         source_count TYPE i,
         target_count TYPE i,
         difference   TYPE i,
         status       TYPE char10,
       END OF ty_recon.

DATA: lt_recon TYPE TABLE OF ty_recon.

" Material Master
SELECT COUNT(*) FROM mara INTO @DATA(lv_target_mat).
" Source count from migration log
SELECT source_count FROM zmig_log
  WHERE object = 'MATERIAL' AND run_id = @p_run_id
  INTO @DATA(lv_source_mat).

APPEND VALUE #(
  object_name  = 'Material Master'
  source_count = lv_source_mat
  target_count = lv_target_mat
  difference   = lv_target_mat - lv_source_mat
  status       = COND #( WHEN lv_target_mat = lv_source_mat THEN 'OK'
                          ELSE 'MISMATCH' )
) TO lt_recon.

" GL Balance reconciliation
" Compare total debit/credit per company code
SELECT bukrs,
       SUM( CASE WHEN shkzg = 'S' THEN dmbtr ELSE 0 END ) AS total_debit,
       SUM( CASE WHEN shkzg = 'H' THEN dmbtr ELSE 0 END ) AS total_credit
  FROM bseg
  WHERE gjahr = @p_fiscal_year
  GROUP BY bukrs
  INTO TABLE @DATA(lt_target_balances).
```

### Pattern 6: Cutover Plan Template

```
CUTOVER PLAN — Go-Live Weekend

Friday Evening (T-36h):
  18:00  Lock source system (stop business transactions)
  18:30  Final delta extract from source
  19:00  Run data quality checks on delta
  20:00  Start delta migration load

Saturday (T-24h):
  06:00  Delta load complete — start validation
  08:00  Run reconciliation reports
  10:00  Fix data issues (correction runs)
  12:00  Business validation (key users)
  14:00  Go/No-Go decision point #1
  15:00  Start integration testing
  18:00  Integration testing complete

Sunday (T-12h):
  06:00  Final reconciliation
  08:00  Go/No-Go decision point #2 (FINAL)
  09:00  Open system for business users
  09:00  Hypercare team on standby
  12:00  First business transactions verified

Rollback triggers:
  - Data reconciliation difference > 1%
  - Critical business process blocked
  - Integration interface failures > threshold
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| LTMC: `Upload failed` | File format error | Wrong template version or encoding | Re-download template from current LTMC version |
| LTMC: `Conversion error` | Value mapping failed | Source value not in mapping table | Add missing mapping; cleanse source data |
| BAPI: `No authorization` | Authorization check failed | Migration user missing roles | Assign S_TCODE + object-specific auth |
| `Duplicate key` | Record already exists | Re-run without clearing previous load | Delete previous test load or use update mode |
| `Number range exhausted` | No numbers available | Number range too small for migration volume | Extend number range via SNRO |
| `Referential integrity` | Dependent object missing | Load order wrong (e.g., PO before vendor) | Follow dependency sequence: master → transactional |
| `Data truncation` | Field length exceeded | Source data longer than target field | Cleanse data or extend custom field length |
| SUM: `Modification check` | Custom code conflict | ABAP modifications incompatible with S/4HANA | Fix with Custom Code Migration Worklist |
| `Lock timeout` | Enqueue failed | Parallel migration jobs competing | Reduce parallelism or partition by org unit |
| LTMC: `Simulate error` | Business rule violation | Data doesn't meet S/4HANA validation rules | Fix source data per validation message |

## Performance Tips

1. **Partition by org unit** — Migrate by company code/plant to parallelize and isolate failures
2. **Disable non-essential exits** — Temporarily deactivate BAdIs/user exits during bulk load
3. **Background processing** — Run LTMC in background mode for large volumes (>10K records)
4. **Number range buffering** — Enable buffering for migration-heavy number ranges
5. **Commit frequency** — Commit every 500-1000 records in custom programs; avoid single mega-commit
6. **Index management** — Drop secondary indexes before bulk load, rebuild after
7. **Load sequence** — Always: Config → Master Data → Open Items → Transactional Data
8. **Test with production volumes** — Never test with 100 records if production has 1M; timing differs non-linearly
9. **Delta strategy** — Plan for multiple delta loads; cutover window depends on delta volume

## Gotchas

- **Business Partner migration**: S/4HANA merges Customer + Vendor into Business Partner — plan BP number assignment carefully
- **Material number length**: S/4HANA supports 40-char material numbers but existing customizing may limit this
- **New GL accounting**: If migrating from classic GL, open items need conversion to new GL structure
- **LTMC template versions**: Templates change with S/4HANA releases — always download from target system
- **Migration user**: Create dedicated migration user with broad auth; don't use dialog user to avoid session limits
- **Tax code mapping**: Tax codes often differ between source and target — map explicitly, never assume
- **Currency conversion**: If migrating across currencies, use ECB rates for the exact cutover date
