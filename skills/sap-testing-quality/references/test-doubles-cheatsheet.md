# SAP Test Doubles Cheat Sheet

## ABAP Unit Test Doubles

### CL_OSQL_TEST_ENVIRONMENT — SQL Test Environment
```abap
" Setup: Create test double for database tables
CLASS-DATA: mo_env TYPE REF TO if_osql_test_environment.

CLASS-METHODS class_setup.
METHOD class_setup.
  mo_env = cl_osql_test_environment=>create(
    i_dependency_list = VALUE #(
      ( 'ZTAB_ORDERS' )
      ( 'ZTAB_ITEMS' )
    )
  ).
ENDMETHOD.

" Before each test: Insert test data
METHOD setup.
  mo_env->clear_doubles( ).
  mo_env->insert_test_data( VALUE ztab_orders(
    ( order_id = 'ORD001' customer = 'CUST01' amount = '100.00' )
    ( order_id = 'ORD002' customer = 'CUST02' amount = '200.00' )
  ) ).
ENDMETHOD.

" Cleanup
METHOD class_teardown.
  mo_env->destroy( ).
ENDMETHOD.
```

### CL_CDS_TEST_ENVIRONMENT — CDS Test Doubles
```abap
" Setup: Create test double for CDS views
CLASS-DATA: mo_cds_env TYPE REF TO if_cds_test_environment.

METHOD class_setup.
  mo_cds_env = cl_cds_test_environment=>create( 'ZI_SALESORDER' ).
ENDMETHOD.

METHOD setup.
  " Insert test data into underlying tables
  mo_cds_env->clear_doubles( ).
  DATA: lt_orders TYPE STANDARD TABLE OF zi_salesorder.
  lt_orders = VALUE #(
    ( salesorder = '001' customer = 'C01' netamount = '500.00' )
  ).
  mo_cds_env->insert_test_data( lt_orders ).
ENDMETHOD.

METHOD class_teardown.
  mo_cds_env->destroy( ).
ENDMETHOD.
```

### CL_BOTD — RAP Test Doubles (Behavior Test Double)
```abap
" Setup: Create test double for RAP BO
CLASS-DATA: mo_botd TYPE REF TO if_botd_txn_buf_test_double.

METHOD class_setup.
  " Create transactional buffer test double
  mo_botd = cl_botd_txn_buf_test_double=>create(
    i_bo_name = 'ZI_SALESORDER'
  ).
ENDMETHOD.

METHOD test_create_order.
  " Arrange: Configure mock data
  mo_botd->configure_create( )->returning(
    VALUE #( ( %cid = 'CID1' salesorder = '001' ) )
  ).

  " Act: Execute EML
  MODIFY ENTITIES OF zi_salesorder
    ENTITY SalesOrder
    CREATE FIELDS ( customer amount )
    WITH VALUE #( ( %cid = 'CID1' customer = 'C01' amount = '500.00' ) )
    MAPPED DATA(mapped)
    FAILED DATA(failed)
    REPORTED DATA(reported).

  " Assert
  cl_abap_unit_assert=>assert_initial( failed ).
  cl_abap_unit_assert=>assert_not_initial( mapped-salesorder ).
ENDMETHOD.
```

### ABAP Test Injection (Test Seams)
```abap
" Production code with test seam
METHOD calculate_price.
  TEST-SEAM get_exchange_rate.
    " Production: call real API
    rv_rate = zcl_exchange_api=>get_rate( iv_currency ).
  END-TEST-SEAM.
  rv_price = iv_amount * rv_rate.
ENDMETHOD.

" Test class: inject test value
METHOD test_calculate_price.
  TEST-INJECTION get_exchange_rate.
    rv_rate = '1.5'.  " Fixed rate for testing
  END-TEST-INJECTION.

  DATA(lv_result) = mo_cut->calculate_price( iv_amount = '100' iv_currency = 'USD' ).
  cl_abap_unit_assert=>assert_equals( act = lv_result exp = '150.00' ).
ENDMETHOD.
```

## CAP (Node.js) Test Doubles

### cds.test() — In-Process Testing
```javascript
const cds = require('@sap/cds');
const { expect } = cds.test('serve', '--in-memory');

describe('OrderService', () => {
  it('should create order', async () => {
    const { Orders } = cds.entities('OrderService');
    const order = await INSERT.into(Orders).entries({
      customer: 'CUST01', amount: 500
    });
    expect(order).to.exist;
  });
});
```

### axios + cds.test() — HTTP Testing
```javascript
const { GET, POST, PATCH, DELETE, expect } = cds.test('serve', '--in-memory');

describe('REST API', () => {
  it('GET /Orders', async () => {
    const { status, data } = await GET('/odata/v4/order/Orders');
    expect(status).to.equal(200);
    expect(data.value).to.be.an('array');
  });

  it('POST /Orders', async () => {
    const { status } = await POST('/odata/v4/order/Orders', {
      customer: 'CUST01', amount: 500
    });
    expect(status).to.equal(201);
  });
});
```

## Quick Reference: Assertion Methods

```abap
" ABAP Unit Assertions
cl_abap_unit_assert=>assert_equals( act = lv_actual exp = lv_expected ).
cl_abap_unit_assert=>assert_not_initial( lv_value ).
cl_abap_unit_assert=>assert_initial( lv_value ).
cl_abap_unit_assert=>assert_true( lv_bool ).
cl_abap_unit_assert=>assert_false( lv_bool ).
cl_abap_unit_assert=>assert_bound( lo_ref ).
cl_abap_unit_assert=>assert_table_contains( line = ls_expected table = lt_actual ).
cl_abap_unit_assert=>assert_number_between( lower = 1 upper = 100 number = lv_num ).
cl_abap_unit_assert=>fail( msg = 'Should not reach here' ).
```
