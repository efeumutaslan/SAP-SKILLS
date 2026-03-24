# Tier 2 Wrapper Pattern — Complete Guide

## When to Use

Use the wrapper pattern when:
- You need functionality only available via a classic API (BAPI, function module)
- No released C1/C2 successor exists
- Your consuming code must run in ABAP Cloud (Tier 1 / Level A)
- Available on: S/4HANA Cloud Private Edition and On-Premise (2022+)
- **Not applicable** to S/4HANA Cloud Public Edition (no classic ABAP at all)

## Architecture

```
┌─────────────────────────────────────┐
│ Tier 1 (ABAP Cloud)                │
│ ┌─────────────────────────────────┐ │
│ │ Z_CONSUMER_CLASS                │ │
│ │ calls: ZIF_PO_CREATE            │ │ ← Released interface (C1)
│ │ via:   ZCL_PO_FACTORY           │ │ ← Released factory (C1)
│ └─────────────────────────────────┘ │
└──────────────┬──────────────────────┘
               │ (factory returns instance)
┌──────────────▼──────────────────────┐
│ Tier 2 (Classic ABAP)              │
│ ┌─────────────────────────────────┐ │
│ │ ZCL_PO_CREATE_IMPL              │ │ ← NOT released
│ │ implements ZIF_PO_CREATE        │ │
│ │ calls BAPI_PO_CREATE1           │ │ ← Classic API
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

## Step-by-Step Implementation

### Step 1: Create Tier 2 Software Component
- In ADT, ensure you have a software component with **classic ABAP** language version
- Package: e.g., `Z_WRAPPER_PO` in this component
- This package CAN access all SAP standard objects (unrestricted)

### Step 2: Define the Interface (in Tier 2 package)
```abap
INTERFACE zif_po_create PUBLIC.

  TYPES:
    BEGIN OF ty_po_header,
      comp_code   TYPE bukrs,
      doc_type    TYPE bsart,
      vendor      TYPE lifnr,
      purch_org   TYPE ekorg,
      pur_group   TYPE ekgrp,
    END OF ty_po_header,

    BEGIN OF ty_po_item,
      po_item     TYPE ebelp,
      material    TYPE matnr,
      quantity    TYPE bstmg,
      plant       TYPE werks_d,
    END OF ty_po_item,

    ty_po_items TYPE STANDARD TABLE OF ty_po_item WITH DEFAULT KEY,

    BEGIN OF ty_po_result,
      po_number TYPE ebeln,
      success   TYPE abap_bool,
      messages  TYPE bapiret2_t,
    END OF ty_po_result.

  METHODS create
    IMPORTING
      is_header TYPE ty_po_header
      it_items  TYPE ty_po_items
    RETURNING
      VALUE(rs_result) TYPE ty_po_result
    RAISING
      zcx_po_error.

ENDINTERFACE.
```

### Step 3: Release the Interface with C1
- In ADT, right-click the interface → Properties → API State
- Set release state: "Released" with contract "C1 — Use System-Internally"
- This makes the interface visible and callable from Tier 1 ABAP Cloud code

### Step 4: Create the Factory Class (in Tier 2 package)
```abap
CLASS zcl_po_create_factory DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create
      RETURNING VALUE(ro_instance) TYPE REF TO zif_po_create.
ENDCLASS.

CLASS zcl_po_create_factory IMPLEMENTATION.
  METHOD create.
    ro_instance = NEW zcl_po_create_impl( ).
  ENDMETHOD.
ENDCLASS.
```

### Step 5: Release the Factory with C1
- Same as Step 3: set API State to "Released" with C1 contract
- The factory is the entry point for Tier 1 consumers

### Step 6: Create the Implementation Class (in Tier 2 package)
```abap
CLASS zcl_po_create_impl DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_po_create.
ENDCLASS.

CLASS zcl_po_create_impl IMPLEMENTATION.
  METHOD zif_po_create~create.
    " Map wrapper types to BAPI types
    DATA ls_poheader TYPE bapimepoheader.
    ls_poheader-comp_code  = is_header-comp_code.
    ls_poheader-doc_type   = is_header-doc_type.
    ls_poheader-vendor     = is_header-vendor.
    ls_poheader-purch_org  = is_header-purch_org.
    ls_poheader-pur_group  = is_header-pur_group.

    DATA ls_poheaderx TYPE bapimepoheaderx.
    ls_poheaderx-comp_code  = abap_true.
    ls_poheaderx-doc_type   = abap_true.
    ls_poheaderx-vendor     = abap_true.
    ls_poheaderx-purch_org  = abap_true.
    ls_poheaderx-pur_group  = abap_true.

    DATA lt_poitem TYPE STANDARD TABLE OF bapimepoitem.
    DATA lt_poitemx TYPE STANDARD TABLE OF bapimepoitemx.
    LOOP AT it_items INTO DATA(ls_item).
      APPEND VALUE bapimepoitem(
        po_item  = ls_item-po_item
        material = ls_item-material
        quantity = ls_item-quantity
        plant    = ls_item-plant
      ) TO lt_poitem.
      APPEND VALUE bapimepoitemx(
        po_item  = ls_item-po_item
        po_itemx = abap_true
        material = abap_true
        quantity = abap_true
        plant    = abap_true
      ) TO lt_poitemx.
    ENDLOOP.

    DATA lv_po_number TYPE bapimepoheader-po_number.
    DATA lt_return TYPE bapiret2_t.

    CALL FUNCTION 'BAPI_PO_CREATE1'
      EXPORTING
        poheader   = ls_poheader
        poheaderx  = ls_poheaderx
      IMPORTING
        exppurchaseorder = lv_po_number
      TABLES
        return     = lt_return
        poitem     = lt_poitem
        poitemx    = lt_poitemx.

    IF lv_po_number IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING wait = abap_true.
      rs_result = VALUE #( po_number = lv_po_number success = abap_true messages = lt_return ).
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      rs_result = VALUE #( success = abap_false messages = lt_return ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

### Step 7: Do NOT Release the Implementation
- The implementation class stays **unreleased**
- Only the interface and factory are released with C1
- Tier 1 code cannot directly instantiate the implementation

### Step 8: Consume from Tier 1

```abap
" In your ABAP Cloud (Tier 1) code:
DATA(lo_po_service) = zcl_po_create_factory=>create( ).

DATA(ls_result) = lo_po_service->create(
  is_header = VALUE #( comp_code = '1000' doc_type = 'NB' vendor = '0000001000'
                        purch_org = '1000' pur_group = '001' )
  it_items  = VALUE #( ( po_item = '00010' material = 'MAT001' quantity = 10 plant = '1000' ) )
).

IF ls_result-success = abap_true.
  " PO created: ls_result-po_number
ELSE.
  " Handle errors from ls_result-messages
ENDIF.
```

## Best Practices

1. **Keep wrappers thin** — Only translate types and call the API. No business logic in the wrapper.
2. **Use custom types** — Don't expose BAPI structures (bapimepoheader) through the interface.
   Define your own types in the interface. This decouples consumers from BAPI internals.
3. **Handle BAPI_TRANSACTION_COMMIT/ROLLBACK** inside the wrapper — Don't leak transaction
   handling to the consumer.
4. **One wrapper per API** — Don't combine multiple BAPIs in one wrapper interface.
5. **Error handling** — Translate BAPIRET2 messages to ABAP Cloud exceptions (CX_ classes)
   or return structured results.
6. **Naming** — `ZIF_<DOMAIN>_<ACTION>` for interface, `ZCL_<DOMAIN>_<ACTION>_FACTORY` for
   factory, `ZCL_<DOMAIN>_<ACTION>_IMPL` for implementation.

## SAP Workshop Reference

Full hands-on workshop: github.com/SAP-samples/abap-platform-rap640
- Exercise 1: Identify missing released APIs
- Exercise 2: Create wrapper interface and factory
- Exercise 3: Implement classic API call
- Exercise 4: Release with C1 contract
- Exercise 5: Consume from RAP BO in Tier 1
