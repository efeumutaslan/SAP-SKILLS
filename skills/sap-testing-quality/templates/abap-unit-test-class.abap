"! ABAP Unit Test Class Template
"! Replace: {{CUT_CLASS}} with class under test
"! Replace: {{TABLE}} with database table(s) to mock
CLASS ltcl_{{CUT_CLASS}} DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA: mo_env TYPE REF TO if_osql_test_environment.
    DATA: mo_cut TYPE REF TO {{CUT_CLASS}}.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    " Test methods — name pattern: test_<scenario>_<expected>
    METHODS test_create_valid_input    FOR TESTING.
    METHODS test_create_missing_field  FOR TESTING.
    METHODS test_read_existing_record  FOR TESTING.
    METHODS test_read_not_found        FOR TESTING.
ENDCLASS.

CLASS ltcl_{{CUT_CLASS}} IMPLEMENTATION.
  METHOD class_setup.
    " Create SQL test environment for database tables
    mo_env = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #(
        ( '{{TABLE}}' )
      )
    ).
  ENDMETHOD.

  METHOD class_teardown.
    mo_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    " Fresh instance + clean test data for each test
    mo_cut = NEW {{CUT_CLASS}}( ).
    mo_env->clear_doubles( ).

    " Insert baseline test data
    mo_env->insert_test_data( VALUE {{TABLE}}(
      ( {{KEY_FIELD}} = 'TEST001' {{FIELD1}} = 'Value1' {{FIELD2}} = 100 )
      ( {{KEY_FIELD}} = 'TEST002' {{FIELD1}} = 'Value2' {{FIELD2}} = 200 )
    ) ).
  ENDMETHOD.

  METHOD teardown.
    " Cleanup if needed
  ENDMETHOD.

  METHOD test_create_valid_input.
    " Arrange
    DATA(ls_input) = VALUE {{STRUCTURE}}(
      {{FIELD1}} = 'NewValue'
      {{FIELD2}} = 300
    ).

    " Act
    DATA(lv_result) = mo_cut->create( ls_input ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = lv_result
      msg = 'Create should return a key'
    ).
  ENDMETHOD.

  METHOD test_create_missing_field.
    " Arrange — missing mandatory field
    DATA(ls_input) = VALUE {{STRUCTURE}}(
      {{FIELD1}} = ''  " Empty mandatory field
    ).

    " Act & Assert — expect exception
    TRY.
        mo_cut->create( ls_input ).
        cl_abap_unit_assert=>fail( msg = 'Should raise exception for missing field' ).
      CATCH {{EXCEPTION_CLASS}} INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_bound( lx_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_read_existing_record.
    " Act
    DATA(ls_result) = mo_cut->read( 'TEST001' ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      act = ls_result-{{FIELD1}}
      exp = 'Value1'
    ).
  ENDMETHOD.

  METHOD test_read_not_found.
    " Act
    DATA(ls_result) = mo_cut->read( 'NONEXISTENT' ).

    " Assert
    cl_abap_unit_assert=>assert_initial(
      act = ls_result
      msg = 'Should return initial for non-existing record'
    ).
  ENDMETHOD.
ENDCLASS.
