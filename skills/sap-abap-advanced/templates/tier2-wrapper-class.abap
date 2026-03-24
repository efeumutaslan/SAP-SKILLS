"! Tier 2 Wrapper Class Template
"! Purpose: Wraps non-released API for consumption by Tier 1 (ABAP Cloud) code
"! Replace: {{CLASSNAME}}, {{METHOD}}, {{PARAMS}}, {{NON_RELEASED_CALL}}
"!
"! Step 1: Create this class with language version "Standard ABAP" (Tier 2)
"! Step 2: Release it with C1 contract for ABAP Cloud consumers
"! Step 3: Consume from Tier 1 classes
CLASS {{CLASSNAME}} DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Release this interface for C1 consumption
    INTERFACES if_released_for_cloud.

    TYPES: BEGIN OF ty_result,
             key_field   TYPE {{KEY_TYPE}},
             value_field TYPE {{VALUE_TYPE}},
             status      TYPE abap_bool,
             message     TYPE string,
           END OF ty_result,
           tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    "! {{METHOD_DESCRIPTION}}
    "! @parameter iv_input | Input parameter
    "! @parameter rv_result | Result
    "! @raising cx_sy_no_handler | If operation fails
    METHODS {{METHOD}}
      IMPORTING iv_input        TYPE {{INPUT_TYPE}}
      RETURNING VALUE(rv_result) TYPE {{RETURN_TYPE}}
      RAISING   cx_sy_no_handler.
ENDCLASS.

CLASS {{CLASSNAME}} IMPLEMENTATION.
  METHOD {{METHOD}}.
    " This uses non-released APIs — allowed in Tier 2
    TRY.
        {{NON_RELEASED_CALL}}
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE cx_sy_no_handler
          EXPORTING previous = lx_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
