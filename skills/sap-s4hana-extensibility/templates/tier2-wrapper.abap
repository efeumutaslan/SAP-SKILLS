"! Tier 2 Wrapper Template
"! Creates a clean interface (released C1) around a classic BAPI
"!
"! Structure:
"!   1. Interface (ZIF_*) — Released with C1 contract
"!   2. Factory (ZCL_*_FACTORY) — Released with C1 contract
"!   3. Implementation (ZCL_*_IMPL) — NOT released (Tier 2, classic ABAP)
"!
"! Replace {{PLACEHOLDER}} values with your actual names

" ============================================================
" PART 1: Interface (release with C1)
" ============================================================
INTERFACE {{ZIF_WRAPPER_NAME}} PUBLIC.

  TYPES:
    BEGIN OF ty_input,
      " Define clean input fields (don't expose BAPI structures)
      {{field1}} TYPE {{data_element1}},
      {{field2}} TYPE {{data_element2}},
    END OF ty_input,

    BEGIN OF ty_result,
      {{key_field}} TYPE {{key_type}},
      success      TYPE abap_bool,
      messages     TYPE bapiret2_t,
    END OF ty_result.

  METHODS execute
    IMPORTING is_input         TYPE ty_input
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   {{ZCX_ERROR_CLASS}}.

ENDINTERFACE.

" ============================================================
" PART 2: Factory (release with C1)
" ============================================================
CLASS {{ZCL_WRAPPER_FACTORY}} DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create
      RETURNING VALUE(ro_instance) TYPE REF TO {{ZIF_WRAPPER_NAME}}.
ENDCLASS.

CLASS {{ZCL_WRAPPER_FACTORY}} IMPLEMENTATION.
  METHOD create.
    ro_instance = NEW {{ZCL_WRAPPER_IMPL}}( ).
  ENDMETHOD.
ENDCLASS.

" ============================================================
" PART 3: Implementation (DO NOT release — classic ABAP)
" ============================================================
CLASS {{ZCL_WRAPPER_IMPL}} DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES {{ZIF_WRAPPER_NAME}}.
ENDCLASS.

CLASS {{ZCL_WRAPPER_IMPL}} IMPLEMENTATION.
  METHOD {{ZIF_WRAPPER_NAME}}~execute.

    " Map interface types to BAPI types
    DATA ls_bapi_input TYPE {{BAPI_INPUT_STRUCTURE}}.
    ls_bapi_input-{{bapi_field1}} = is_input-{{field1}}.
    ls_bapi_input-{{bapi_field2}} = is_input-{{field2}}.

    DATA lt_return TYPE bapiret2_t.
    DATA lv_key TYPE {{key_type}}.

    " Call classic BAPI
    CALL FUNCTION '{{BAPI_NAME}}'
      EXPORTING
        {{bapi_import_param}} = ls_bapi_input
      IMPORTING
        {{bapi_export_param}} = lv_key
      TABLES
        return               = lt_return.

    " Check result and commit/rollback
    IF lv_key IS NOT INITIAL.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING wait = abap_true.
      rs_result = VALUE #( {{key_field}} = lv_key success = abap_true messages = lt_return ).
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      rs_result = VALUE #( success = abap_false messages = lt_return ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
