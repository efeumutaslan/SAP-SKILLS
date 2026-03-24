"! RAP Handler Class Template
"! Replace {{PLACEHOLDER}} values with your actual names
"!
"! This template covers the most common handler methods:
"!   - Determination (SetDefaults)
"!   - Validation (ValidateDescription)
"!   - Action (Accept)
"!   - Feature Control (get_instance_features)
"!   - Authorization (global + instance)
CLASS {{ZBP_I_ENTITY}} DEFINITION PUBLIC ABSTRACT FINAL
  FOR BEHAVIOR OF {{ZI_ENTITY}}.
ENDCLASS.

CLASS {{ZBP_I_ENTITY}} IMPLEMENTATION.
ENDCLASS.

" --- Local Handler Class ---
CLASS lhc_{{entity}} DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " Determination: Set defaults on create
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR {{Entity}}~SetDefaults.

    " Validation: Check mandatory fields before save
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR {{Entity}}~ValidateDescription.

    " Action: Accept entity
    METHODS accept FOR MODIFY
      IMPORTING keys FOR ACTION {{Entity}}~Accept RESULT result.

    " Feature Control: Enable/disable actions based on state
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR {{Entity}} RESULT result.

    " Authorization: Global (can user create?)
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR {{Entity}} RESULT result.

    " Authorization: Instance (can user modify THIS entity?)
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR {{Entity}} RESULT result.

ENDCLASS.

CLASS lhc_{{entity}} IMPLEMENTATION.

  METHOD setDefaults.
    READ ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    MODIFY ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR entity IN lt_entities
        WHERE ( Status IS INITIAL )
        ( %tky = entity-%tky  Status = 'N' ) ).  " N = New
  ENDMETHOD.

  METHOD validateDescription.
    READ ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      FIELDS ( Description )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    LOOP AT lt_entities INTO DATA(ls_entity).
      IF ls_entity-Description IS INITIAL.
        APPEND VALUE #( %tky = ls_entity-%tky ) TO failed-{{entity}}.
        APPEND VALUE #( %tky = ls_entity-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Description is mandatory' )
          %element-Description = if_abap_behv=>mk-on
        ) TO reported-{{entity}}.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD accept.
    MODIFY ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR key IN keys
        ( %tky = key-%tky  Status = 'A' ) ).  " A = Accepted

    READ ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    result = VALUE #( FOR entity IN lt_entities
      ( %tky = entity-%tky  %param = entity ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    result = VALUE #( FOR entity IN lt_entities
      ( %tky = entity-%tky
        %action-Accept = COND #(
          WHEN entity-Status = 'A'
          THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled )
      ) ).
  ENDMETHOD.

  METHOD get_global_authorizations.
    " Check if user can create entities at all
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT '{{Z_AUTH_OBJECT}}'
        ID 'ACTVT' FIELD '01'.  " 01 = Create
      result-%create = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT '{{Z_AUTH_OBJECT}}'
        ID 'ACTVT' FIELD '02'.  " 02 = Change
      result-%update = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT '{{Z_AUTH_OBJECT}}'
        ID 'ACTVT' FIELD '06'.  " 06 = Delete
      result-%delete = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " Check if user can modify THIS specific entity
    READ ENTITIES OF {{zi_entity}} IN LOCAL MODE
      ENTITY {{Entity}}
      FIELDS ( {{OrgField}} )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_entities).

    LOOP AT lt_entities INTO DATA(ls_entity).
      AUTHORITY-CHECK OBJECT '{{Z_AUTH_OBJECT}}'
        ID 'ACTVT' FIELD '02'
        ID '{{Z_ORG_FIELD}}' FIELD ls_entity-{{OrgField}}.

      DATA(lv_auth) = COND #(
        WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
        ELSE if_abap_behv=>auth-unauthorized ).

      APPEND VALUE #( %tky = ls_entity-%tky
        %update = lv_auth
        %delete = lv_auth
        %action-Accept = lv_auth
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
