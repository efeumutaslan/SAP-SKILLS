"! Cloud BAdI Implementation Template
"! Replace {{PLACEHOLDER}} values with your actual names
"!
"! Prerequisites:
"!   - ABAP Cloud language version
"!   - Released BAdI definition (C0 contract)
"!   - Enhancement implementation created in ADT
CLASS {{ZCL_BADI_CLASS_NAME}} DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_badi_interface.
    INTERFACES {{IF_BADI_INTERFACE_NAME}}.
ENDCLASS.

CLASS {{ZCL_BADI_CLASS_NAME}} IMPLEMENTATION.

  METHOD {{IF_BADI_INTERFACE_NAME}}~{{METHOD_NAME}}.
    " --- Validation Example ---
    LOOP AT {{ENTITY_TABLE}} ASSIGNING FIELD-SYMBOL(<entity>).

      " Add your validation condition
      IF <entity>-{{FIELD_TO_CHECK}} IS INITIAL.

        " Report error message
        APPEND VALUE #(
          %tky   = <entity>-%tky
          %msg   = new_message(
            id       = '{{MESSAGE_CLASS}}'
            number   = '{{MESSAGE_NUMBER}}'
            severity = if_abap_behv_message=>severity-error
            v1       = <entity>-{{KEY_FIELD}} )
        ) TO reported-{{ENTITY_NAME}}.

        " Mark as failed (prevents save)
        APPEND VALUE #(
          %tky = <entity>-%tky
        ) TO failed-{{ENTITY_NAME}}.

      ENDIF.

    ENDLOOP.

    " --- Determination Example (modify data) ---
    " LOOP AT {{ENTITY_TABLE}} ASSIGNING FIELD-SYMBOL(<entity>).
    "   IF <entity>-{{FIELD_TO_SET}} IS INITIAL.
    "     <entity>-{{FIELD_TO_SET}} = '{{DEFAULT_VALUE}}'.
    "   ENDIF.
    " ENDLOOP.

  ENDMETHOD.

ENDCLASS.
