---
name: sap-abap-advanced
description: |
  Advanced ABAP development skill complementing the base sap-abap skill. Use when: working with
  ABAP Cloud (Tier 1) vs Classic ABAP (Tier 2) distinction, ABAP Environment on BTP (Steampunk),
  AMDP (ABAP Managed Database Procedures), ABAP for HANA optimization, abapGit workflows,
  Released API checks (Cloudification Repository), ABAP RESTful HTTP handlers, dynamic
  programming with RTTI/RTTC, or migrating classic ABAP to ABAP Cloud. Extends the base
  sap-abap skill with cloud-era patterns.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# Advanced ABAP — Cloud, HANA-Optimized & Modern Patterns

## Related Skills
- `sap-abap` — Base ABAP skill (syntax, internal tables, OOP fundamentals)
- `sap-rap-comprehensive` — RAP Business Objects built with ABAP Cloud
- `sap-hana-cloud` — HANA database features consumed via AMDP
- `sap-devops-cicd` — abapGit + gCTS pipeline integration
- `sap-migration` — Classic → Cloud ABAP migration

## Quick Start

**ABAP Cloud (Tier 1) vs Classic ABAP (Tier 2):**

| Aspect | ABAP Cloud (Tier 1) | Classic ABAP (Tier 2) |
|--------|---------------------|----------------------|
| API Access | Released APIs only | All APIs (including internal) |
| Where | BTP Steampunk, S/4HANA Cloud Public | S/4HANA Private, On-Premise |
| Language version | `ABAP for Cloud Development` | `Standard ABAP` |
| DB access | ABAP SQL only (no native SQL) | ABAP SQL + Native SQL + ADBC |
| Extensibility | RAP, Released BAdIs only | All enhancement techniques |
| Naming | Namespace `/.../ ` or `Z`/`Y` with prefix | `Z`/`Y` prefix |

**Check if API is released:**
```abap
" In ADT: Open element → Properties → API State
" Or: ABAP Cloud: compilation error if not released
" Or: Cloudification Repository (api.sap.com)
```

## Core Concepts

### ABAP Cloud Restrictions
What you **cannot** use in ABAP Cloud:
- `SELECT ... FROM <db_table>` on non-released tables → Use released CDS views
- `CALL FUNCTION` on non-released FMs → Use released APIs/classes
- `WRITE` / `SUBMIT` / `CALL TRANSACTION` → Use RAP / HTTP services
- `SY-SUBRC` after non-ABAP-SQL statements → Use exceptions
- `INCLUDE`, `FORM/PERFORM` → Use classes/methods
- Direct DB modifications (`INSERT/UPDATE/DELETE dbtab`) on non-owned tables

### ABAP Language Version (Since 2022)
```abap
" Set in class/interface/program attributes:
" Option 1: ABAP for Cloud Development (Tier 1 — released APIs only)
" Option 2: Standard ABAP (Tier 2 — full access)
" Option 3: ABAP for Key Users (limited, no-code)

" Check programmatically:
DATA(lv_version) = cl_abap_context_info=>get_abap_language_version( ).
" Returns: 'CLOUD' | 'STANDARD' | 'KEYUSER'
```

### Released API Categories
| Category | Example | Check Method |
|----------|---------|-------------|
| Released CDS View | `I_BusinessPartner` | Prefix `I_` or `C_`, annotation `@ObjectModel.usageType` |
| Released Class | `CL_BCS_MAIL_MESSAGE` | ADT: API State = Released |
| Released Interface | `IF_HTTP_SERVICE_EXTENSION` | ADT: API State = Released |
| Released BAdI | `BADI_IDENTITY_CHECK` | Enhancement Spot → Released flag |
| Released RAP BO | `I_BankTP` | Behavior definition → Released |

## Common Patterns

### Pattern 1: AMDP — ABAP Managed Database Procedures

```abap
CLASS zcl_amdp_examples DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.

    TYPES: BEGIN OF ty_sales_summary,
             customer_id TYPE vbak-kunnr,
             total_amount TYPE vbak-netwr,
             order_count TYPE i,
             avg_amount TYPE vbak-netwr,
           END OF ty_sales_summary,
           tt_sales_summary TYPE STANDARD TABLE OF ty_sales_summary WITH EMPTY KEY.

    " Table function (consumed in CDS)
    CLASS-METHODS get_sales_summary
      FOR TABLE FUNCTION z_tf_sales_summary.

    " Regular AMDP method
    CLASS-METHODS calculate_running_total
      IMPORTING VALUE(iv_customer) TYPE kunnr
                VALUE(iv_year)     TYPE gjahr
      EXPORTING VALUE(et_result)   TYPE tt_sales_summary
      RAISING   cx_amdp_execution_error.
ENDCLASS.

CLASS zcl_amdp_examples IMPLEMENTATION.
  METHOD get_sales_summary BY DATABASE FUNCTION
    FOR HDB
    LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING vbak vbap.

    RETURN SELECT
      k.kunnr AS customer_id,
      SUM(p.netwr) AS total_amount,
      COUNT(DISTINCT k.vbeln) AS order_count,
      AVG(p.netwr) AS avg_amount
    FROM vbak AS k
    INNER JOIN vbap AS p ON k.vbeln = p.vbeln
    WHERE k.erdat >= :iv_date_from
      AND k.erdat <= :iv_date_to
    GROUP BY k.kunnr;
  ENDMETHOD.

  METHOD calculate_running_total BY DATABASE PROCEDURE
    FOR HDB
    LANGUAGE SQLSCRIPT
    OPTIONS READ-ONLY
    USING vbak.

    et_result = SELECT
      kunnr AS customer_id,
      netwr AS total_amount,
      ROW_NUMBER() OVER (ORDER BY erdat) AS order_count,
      SUM(netwr) OVER (ORDER BY erdat ROWS UNBOUNDED PRECEDING) AS avg_amount
    FROM vbak
    WHERE kunnr = :iv_customer
      AND LEFT(erdat, 4) = :iv_year;
  ENDMETHOD.
ENDCLASS.
```

### Pattern 2: ABAP Cloud — HTTP Service Handler

```abap
CLASS zcl_http_handler DEFINITION PUBLIC
  FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_http_service_extension.
ENDCLASS.

CLASS zcl_http_handler IMPLEMENTATION.
  METHOD if_http_service_extension~handle_request.
    CASE request->get_method( ).
      WHEN 'GET'.
        handle_get( request = request response = response ).
      WHEN 'POST'.
        handle_post( request = request response = response ).
      WHEN OTHERS.
        response->set_status( 405 ).
        response->set_text( '{"error":"Method not allowed"}' ).
    ENDCASE.
  ENDMETHOD.

  METHOD handle_get.
    DATA(lv_id) = request->get_uri_query_parameter( 'id' ).

    TRY.
        SELECT SINGLE * FROM zi_myentity WHERE id = @lv_id INTO @DATA(ls_entity).
        IF sy-subrc <> 0.
          response->set_status( 404 ).
          response->set_text( '{"error":"Not found"}' ).
          RETURN.
        ENDIF.

        response->set_status( 200 ).
        response->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
        response->set_text( /ui2/cl_json=>serialize( data = ls_entity ) ).
      CATCH cx_root INTO DATA(lx_error).
        response->set_status( 500 ).
        response->set_text( |{{"error":"{ lx_error->get_text( ) }"}}| ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

### Pattern 3: abapGit Workflow

```
Development Workflow with abapGit:
┌─────────────┐     ┌──────────┐     ┌──────────┐
│ ABAP System │────►│ abapGit  │────►│  GitHub   │
│ (DEV)       │◄────│ (tcode:  │◄────│  Repo     │
│             │     │  ZABAPGIT)│     │           │
└─────────────┘     └──────────┘     └──────────┘
```

**Best practices:**
1. One Git repo per package (or package tree root)
2. Use `.abapgit.xml` for serialization settings
3. Never commit generated artifacts (proxies, number range objects)
4. Use transport-based deployment to QA/PRD (not abapGit pull)
5. Branch strategy: `main` (PRD state) + `dev` + feature branches

```xml
<!-- .abapgit.xml -->
<?xml version="1.0" encoding="utf-8"?>
<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
 <asx:values>
  <DATA>
   <MASTER_LANGUAGE>E</MASTER_LANGUAGE>
   <STARTING_FOLDER>/src/</STARTING_FOLDER>
   <FOLDER_LOGIC>PREFIX</FOLDER_LOGIC>
   <IGNORE>
    <item>/.gitignore</item>
    <item>/LICENSE</item>
    <item>/README.md</item>
    <item>/package.json</item>
    <item>/.travis.yml</item>
   </IGNORE>
  </DATA>
 </asx:values>
</asx:abap>
```

### Pattern 4: Released API Wrapper Pattern

```abap
" When you need non-released functionality in ABAP Cloud,
" create a Tier 2 wrapper and release it

" Step 1: Tier 2 class (Standard ABAP) — wraps non-released API
CLASS zcl_legacy_wrapper DEFINITION PUBLIC
  FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    " Mark with C1 release contract
    INTERFACES if_released_for_cloud.

    METHODS get_customer_credit
      IMPORTING iv_customer    TYPE kunnr
      RETURNING VALUE(rv_limit) TYPE knkk-klimk
      RAISING   cx_sy_no_handler.
ENDCLASS.

CLASS zcl_legacy_wrapper IMPLEMENTATION.
  METHOD get_customer_credit.
    " This uses non-released table KNKK — allowed in Tier 2
    SELECT SINGLE klimk FROM knkk
      WHERE kunnr = @iv_customer
      INTO @rv_limit.
  ENDMETHOD.
ENDCLASS.

" Step 2: Tier 1 consumer (ABAP Cloud) — uses released wrapper
CLASS zcl_cloud_consumer DEFINITION PUBLIC
  FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS check_credit_limit
      IMPORTING iv_customer TYPE kunnr
                iv_amount   TYPE netwr
      RETURNING VALUE(rv_ok) TYPE abap_bool.
ENDCLASS.

CLASS zcl_cloud_consumer IMPLEMENTATION.
  METHOD check_credit_limit.
    DATA(lo_wrapper) = NEW zcl_legacy_wrapper( ).
    DATA(lv_limit) = lo_wrapper->get_customer_credit( iv_customer ).
    rv_ok = xsdbool( iv_amount <= lv_limit ).
  ENDMETHOD.
ENDCLASS.
```

### Pattern 5: ABAP SQL — HANA-Optimized Patterns

```abap
" Window functions (pushed to HANA)
SELECT customer, order_date, amount,
       SUM( amount ) OVER( PARTITION BY customer
                           ORDER BY order_date
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )
         AS running_total,
       ROW_NUMBER( ) OVER( PARTITION BY customer ORDER BY amount DESC )
         AS rank
  FROM zorders
  INTO TABLE @DATA(lt_ranked).

" String aggregation
SELECT customer,
       STRING_AGG( product, ', ' ORDER BY product ) AS all_products
  FROM zorder_items
  GROUP BY customer
  INTO TABLE @DATA(lt_agg).

" Hierarchies in ABAP SQL
WITH +hierarchy AS (
  SELECT FROM zi_org_unit AS org
    FIELDS org~id, org~parent_id, org~name,
           $node.hierarchy_rank AS rank,
           $node.hierarchy_level AS level
    WHERE HIERARCHY_ANCESTORS( source = zi_org_unit
                               child_id = '1000'
                               start WHERE id = org~id )
)
SELECT FROM +hierarchy FIELDS * INTO TABLE @DATA(lt_hier).

" Privileged access in RAP (bypass auth for internal reads)
SELECT FROM zi_salesorder
  FIELDS *
  WHERE status = 'OPEN'
  INTO TABLE @DATA(lt_open)
  PRIVILEGED ACCESS.
```

### Pattern 6: Dynamic Programming with RTTI/RTTC

```abap
" Create structure dynamically at runtime
METHOD create_dynamic_structure.
  DATA: lt_components TYPE cl_abap_structdescr=>component_table.

  " Build component list
  lt_components = VALUE #(
    ( name = 'ID'     type = cl_abap_elemdescr=>get_string( ) )
    ( name = 'NAME'   type = cl_abap_elemdescr=>get_string( ) )
    ( name = 'AMOUNT' type = cl_abap_elemdescr=>get_p( p_length = 8 p_decimals = 2 ) )
  ).

  " Add dynamic fields from config
  LOOP AT it_custom_fields ASSIGNING FIELD-SYMBOL(<field>).
    APPEND VALUE #(
      name = <field>-fieldname
      type = SWITCH #( <field>-datatype
               WHEN 'STRING' THEN cl_abap_elemdescr=>get_string( )
               WHEN 'INT'    THEN cl_abap_elemdescr=>get_i( )
               WHEN 'DATE'   THEN cl_abap_elemdescr=>get_d( ) )
    ) TO lt_components.
  ENDLOOP.

  " Create types
  DATA(lo_struct) = cl_abap_structdescr=>create( lt_components ).
  DATA(lo_table) = cl_abap_tabledescr=>create( lo_struct ).

  " Create data references
  CREATE DATA rr_table TYPE HANDLE lo_table.
  ASSIGN rr_table->* TO FIELD-SYMBOL(<table>).

  " Now use <table> for dynamic SELECT
  SELECT (it_fieldlist) FROM (iv_tablename)
    INTO CORRESPONDING FIELDS OF TABLE @<table>
    UP TO iv_max_rows ROWS.
ENDMETHOD.
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `Use of non-released API` | Not released for ABAP Cloud | Using Tier 2 API in Tier 1 | Find released alternative or create Tier 2 wrapper |
| `AMDP: Syntax error` | SQLScript compilation failed | Invalid SQLScript in AMDP method | Check HANA SQL syntax; test in HANA SQL Console |
| `CX_AMDP_EXECUTION_ERROR` | AMDP runtime failure | Data type mismatch or HANA error | Check parameter types match HANA equivalents |
| `abapGit: Deserialization` | Object import failed | Conflicting object in target system | Check package assignment; resolve naming conflicts |
| `abapGit: Auth error` | GitHub authentication failed | Token expired or wrong permissions | Regenerate personal access token with repo scope |
| `ABAP SQL: Syntax not allowed` | Feature not available | SQL feature not supported in ABAP Cloud | Check ABAP release notes for SQL feature availability |
| `Released API deprecated` | Successor API available | Using deprecated released API | Migrate to successor (check ADT deprecation info) |
| `Tier mismatch` | Cannot use Tier 1 in Tier 2 context | Mixing language versions incorrectly | Keep clean tier separation; wrappers go Tier 2 → Tier 1 |

## Performance Tips

1. **Push down to HANA** — Use AMDP for complex calculations; avoid ABAP loops for aggregation
2. **ABAP SQL over Open SQL** — New ABAP SQL features (window functions, CTEs) execute on DB
3. **Avoid SELECT in loops** — Use JOINs or associations; even with buffered tables, loop SELECTs are anti-patterns
4. **Buffer wisely** — `cl_abap_context_info=>get_system_date()` is buffered; `sy-datum` triggers DB call per access in cloud
5. **AMDP table functions** — For CDS consumption, table functions outperform calculated fields for complex logic
6. **Parallel processing** — Use `CL_ABAP_PARALLEL` for cloud-compatible parallel RFC replacement
7. **String operations** — Use string templates `|{ }|` over `CONCATENATE`; they're optimized in cloud runtime

## Gotchas

- **No SE80/SE38 in Cloud**: Use ADT (Eclipse) exclusively for ABAP Cloud development
- **No transport in Steampunk**: BTP ABAP Environment uses software components + Git, not transport requests
- **AMDP debugging**: Set breakpoints in ADT; SQLScript debugging requires HANA permissions
- **abapGit and namespaces**: Namespace `/MYNAMESPACE/` objects need special serializer configuration
- **Released API stability**: C1 (released) APIs have backward-compatible contract; C0 can change anytime
- **Tier 2 is not "legacy"**: Tier 2 (Standard ABAP) is valid for S/4HANA Private/On-Premise — it's not deprecated
