"! RAP Unit Test Template using CL_BOTD Test Doubles
"! Replace {{PLACEHOLDER}} values with your actual names
"!
"! Framework: CL_BOTD_TXBUFDBL_BO_TEST_ENV (Transactional Buffer Test Double)
"! Use this for testing RAP handler methods without a real database.
CLASS {{ZTC_ENTITY}} DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA: mo_environment TYPE REF TO if_botd_txbufdbl_bo_test_env.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.

    " Test methods
    METHODS create_entity        FOR TESTING.
    METHODS validate_description FOR TESTING.
    METHODS accept_action        FOR TESTING.
    METHODS feature_control      FOR TESTING.
ENDCLASS.

CLASS {{ZTC_ENTITY}} IMPLEMENTATION.

  METHOD class_setup.
    " Create the test double environment for the RAP BO
    mo_environment = cl_botd_txbufdbl_bo_test_env=>create(
      VALUE #( ( {{ZI_ENTITY}} ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    mo_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    " Clear test double buffer before each test
    mo_environment->clear_doubles( ).
  ENDMETHOD.

  METHOD create_entity.
    " Test: Create a new entity via EML
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      CREATE FIELDS ( Description Status )
      WITH VALUE #( (
        %cid        = 'TEST_CREATE_1'
        Description = 'Test Entity'
        Status      = 'N'
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    " Assert: No failures
    cl_abap_unit_assert=>assert_initial(
      act = ls_failed-{{entity}}
      msg = 'Create should not fail' ).

    " Assert: Mapped contains the created entity
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_mapped-{{entity}}
      msg = 'Mapped should contain the new entity' ).

    " Commit to trigger on-save validations/determinations
    COMMIT ENTITIES
      RESPONSE OF {{zi_entity}}
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    cl_abap_unit_assert=>assert_initial(
      act = ls_commit_failed-{{entity}}
      msg = 'Commit should not fail' ).
  ENDMETHOD.

  METHOD validate_description.
    " Test: Validation rejects empty description
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      CREATE FIELDS ( Description )
      WITH VALUE #( (
        %cid        = 'TEST_VALIDATE_1'
        Description = ''    " Empty — should trigger validation error
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    " Commit to trigger on-save validations
    COMMIT ENTITIES
      RESPONSE OF {{zi_entity}}
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    " Assert: Commit should fail due to validation
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_commit_failed-{{entity}}
      msg = 'Commit should fail — description is mandatory' ).
  ENDMETHOD.

  METHOD accept_action.
    " Setup: Create an entity first
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      CREATE FIELDS ( Description Status )
      WITH VALUE #( (
        %cid        = 'TEST_ACTION_1'
        Description = 'Test for Action'
        Status      = 'N'
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES.

    " Execute: Run the Accept action
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      EXECUTE Accept
      FROM VALUE #( (
        %tky = ls_mapped-{{entity}}[ 1 ]-%tky
      ) )
      RESULT DATA(lt_result)
      FAILED DATA(ls_action_failed)
      REPORTED DATA(ls_action_reported).

    " Assert: Action succeeded and status changed
    cl_abap_unit_assert=>assert_initial(
      act = ls_action_failed-{{entity}}
      msg = 'Accept action should not fail' ).

    cl_abap_unit_assert=>assert_equals(
      exp = 'A'
      act = lt_result[ 1 ]-%param-Status
      msg = 'Status should be A (Accepted)' ).
  ENDMETHOD.

  METHOD feature_control.
    " Setup: Create an already-accepted entity
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      CREATE FIELDS ( Description Status )
      WITH VALUE #( (
        %cid        = 'TEST_FC_1'
        Description = 'Test FC'
        Status      = 'A'    " Already accepted
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    COMMIT ENTITIES.

    " Read with feature control
    READ ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      ALL FIELDS
      WITH VALUE #( (
        %tky = ls_mapped-{{entity}}[ 1 ]-%tky
      ) )
      RESULT DATA(lt_result).

    " Note: Feature control is tested indirectly.
    " The action should fail because the entity is already accepted.
    MODIFY ENTITIES OF {{zi_entity}}
      ENTITY {{Entity}}
      EXECUTE Accept
      FROM VALUE #( (
        %tky = ls_mapped-{{entity}}[ 1 ]-%tky
      ) )
      FAILED DATA(ls_fc_failed)
      REPORTED DATA(ls_fc_reported).

    " Feature control should prevent the action
    " (depends on whether FC raises an error or silently skips)
  ENDMETHOD.

ENDCLASS.
