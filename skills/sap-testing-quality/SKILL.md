---
name: sap-testing-quality
description: |
  SAP testing and quality assurance skill. Use when: writing ABAP Unit tests, implementing
  test doubles and dependency injection in ABAP, setting up CAP/Node.js or CAP/Java tests,
  creating OPA5/UI5 integration tests, using SAP Cloud ALM for test management, implementing
  contract testing for APIs, load testing SAP systems, working with ABAP Test Cockpit (ATC),
  code inspector checks, test-driven development in SAP, or setting up CI/CD test pipelines.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP Testing & Quality Assurance

## Related Skills
- `sap-rap-comprehensive` — RAP BO testing patterns, EML-based test assertions
- `sap-devops-cicd` — Integrating tests into CI/CD pipelines, ATC in CI

## Quick Start

**Choose your testing approach:**

| Layer | Framework | Tool |
|-------|-----------|------|
| ABAP backend logic | ABAP Unit | ADT Test Runner / ATC |
| ABAP SQL / CDS | CDS Test Double Framework | `CL_CDS_TEST_ENVIRONMENT` |
| RAP Business Objects | RAP BO Test | EML + `CL_BOTD_TXBUFDBL_BO_TEST_ENV` |
| CAP Node.js services | cds.test + Jest/Mocha | `cds test` CLI |
| CAP Java services | JUnit 5 + Spring Test | `mvn test` |
| UI5/Fiori frontend | OPA5 + QUnit | UI5 Test Runner |
| API contract testing | REST/OData assertions | Postman / Newman / custom |
| Performance | JMeter / k6 | Load test scripts |

## Core Concepts

### ABAP Unit Architecture
- **Test classes**: Local class with `FOR TESTING` addition
- **Risk levels**: `HARMLESS`, `DANGEROUS`, `CRITICAL` — controls what DB changes are allowed
- **Duration**: `SHORT` (<1s), `MEDIUM` (<10s), `LONG` (>10s)
- **Test isolation**: Use test doubles to isolate unit under test from DB, authority checks, etc.
- **Test relations**: `FOR TESTING RISK LEVEL` annotations on test class definition

### Test Double Frameworks

| Framework | Class | Purpose |
|-----------|-------|---------|
| ABAP Test Double Framework | `CL_ABAP_TESTDOUBLE` | Mock any interface |
| SQL Test Environment | `CL_OSQL_TEST_ENVIRONMENT` | Redirect DB tables to test data |
| CDS Test Double | `CL_CDS_TEST_ENVIRONMENT` | Test CDS views with mock data |
| Authority Check Double | `CL_AUNIT_AUTHORITY_CHECK` | Stub authority checks |
| RAP BO Test Double | `CL_BOTD_TXBUFDBL_BO_TEST_ENV` | Test RAP BOs without DB |

### ATC (ABAP Test Cockpit)
- Centralized quality gate for ABAP code
- Runs: syntax check, naming conventions, performance patterns, security checks, custom checks
- Integrable into CI/CD via `ABAP Environment Pipeline` or API
- Exemptions managed via `ATC Exemption` workflow

## Common Patterns

### Pattern 1: ABAP Unit with Test Doubles

```abap
" Production class
CLASS zcl_order_validator DEFINITION PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_order_validator.
    METHODS constructor
      IMPORTING io_order_repo TYPE REF TO zif_order_repository.
  PRIVATE SECTION.
    DATA mo_repo TYPE REF TO zif_order_repository.
ENDCLASS.

CLASS zcl_order_validator IMPLEMENTATION.
  METHOD constructor.
    mo_repo = io_order_repo.
  ENDMETHOD.
  METHOD zif_order_validator~validate.
    DATA(ls_order) = mo_repo->get_order( iv_order_id ).
    IF ls_order-amount <= 0.
      APPEND VALUE #( type = 'E' message = 'Amount must be positive' ) TO rt_messages.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

" Test class
CLASS ltcl_order_validator DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_order_validator.
    DATA mo_repo_mock TYPE REF TO zif_order_repository.
    METHODS setup.
    METHODS invalid_amount FOR TESTING.
    METHODS valid_order FOR TESTING.
ENDCLASS.

CLASS ltcl_order_validator IMPLEMENTATION.
  METHOD setup.
    mo_repo_mock = CAST #( cl_abap_testdouble=>create( 'ZIF_ORDER_REPOSITORY' ) ).
    mo_cut = NEW #( io_order_repo = mo_repo_mock ).
  ENDMETHOD.

  METHOD invalid_amount.
    " Arrange
    DATA(ls_order) = VALUE zs_order( order_id = 'ORD001' amount = -100 ).
    cl_abap_testdouble=>configure_call( mo_repo_mock
      )->returning( ls_order
      )->and_expect( )->is_called_once( ).
    mo_repo_mock->get_order( 'ORD001' ).

    " Act
    DATA(lt_messages) = mo_cut->zif_order_validator~validate( 'ORD001' ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial( lt_messages ).
    cl_abap_unit_assert=>assert_equals( exp = 'E' act = lt_messages[ 1 ]-type ).

    " Verify mock
    cl_abap_testdouble=>verify_expectations( mo_repo_mock ).
  ENDMETHOD.

  METHOD valid_order.
    DATA(ls_order) = VALUE zs_order( order_id = 'ORD002' amount = 500 ).
    cl_abap_testdouble=>configure_call( mo_repo_mock
      )->returning( ls_order ).
    mo_repo_mock->get_order( 'ORD002' ).

    DATA(lt_messages) = mo_cut->zif_order_validator~validate( 'ORD002' ).
    cl_abap_unit_assert=>assert_initial( lt_messages ).
  ENDMETHOD.
ENDCLASS.
```

### Pattern 2: SQL Test Environment

```abap
CLASS ltcl_order_report DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CLASS-DATA go_sql_env TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS total_by_customer FOR TESTING.
ENDCLASS.

CLASS ltcl_order_report IMPLEMENTATION.
  METHOD class_setup.
    go_sql_env = cl_osql_test_environment=>create( i_dependency_list = VALUE #(
      ( 'ZORDERS' )
      ( 'ZCUSTOMERS' )
    ) ).
  ENDMETHOD.

  METHOD class_teardown.
    go_sql_env->destroy( ).
  ENDMETHOD.

  METHOD total_by_customer.
    " Arrange — insert test data into double
    go_sql_env->clear_doubles( ).
    go_sql_env->insert_test_data( EXPORTING i_data = VALUE zt_orders(
      ( order_id = 'O1' customer_id = 'C1' amount = '100.00' )
      ( order_id = 'O2' customer_id = 'C1' amount = '250.00' )
      ( order_id = 'O3' customer_id = 'C2' amount = '75.00' )
    ) ).

    " Act
    DATA(lt_result) = NEW zcl_order_report( )->get_totals_by_customer( ).

    " Assert
    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( lt_result ) ).
    READ TABLE lt_result INTO DATA(ls_c1) WITH KEY customer_id = 'C1'.
    cl_abap_unit_assert=>assert_equals( exp = '350.00' act = ls_c1-total ).
  ENDMETHOD.
ENDCLASS.
```

### Pattern 3: CDS Test Double Framework

```abap
CLASS ltcl_cds_view DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    CLASS-DATA go_cds_env TYPE REF TO if_cds_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS active_orders_only FOR TESTING.
ENDCLASS.

CLASS ltcl_cds_view IMPLEMENTATION.
  METHOD class_setup.
    go_cds_env = cl_cds_test_environment=>create( i_for_entity = 'ZI_ORDER' ).
    go_cds_env->enable_double_redirection( ).
  ENDMETHOD.

  METHOD class_teardown.
    go_cds_env->destroy( ).
  ENDMETHOD.

  METHOD active_orders_only.
    " Insert test data into underlying tables via SQL doubles
    DATA lt_orders TYPE TABLE OF zorders.
    lt_orders = VALUE #(
      ( order_id = 'O1' status = 'ACTIVE' amount = '100.00' )
      ( order_id = 'O2' status = 'CLOSED' amount = '200.00' )
    ).
    go_cds_env->insert_test_data( i_data = lt_orders ).

    " Execute CDS view
    SELECT * FROM zi_order INTO TABLE @DATA(lt_result).

    " Assert: only active orders returned (CDS has WHERE status = 'ACTIVE')
    cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( lt_result ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'O1' act = lt_result[ 1 ]-OrderId ).
  ENDMETHOD.
ENDCLASS.
```

### Pattern 4: CAP Node.js Test (cds.test)

```javascript
const cds = require('@sap/cds');
const { expect } = cds.test('serve', '--project', __dirname + '/..');

describe('OrderService', () => {
  it('should create an order', async () => {
    const { data } = await cds.run(INSERT.into('Orders').entries({
      ID: 'uuid-001', item: 'Laptop', quantity: 2, amount: 2000
    }));
    expect(data).to.exist;
  });

  it('should reject negative amount', async () => {
    try {
      await cds.run(INSERT.into('Orders').entries({
        ID: 'uuid-002', item: 'Phone', quantity: 1, amount: -100
      }));
      expect.fail('Should have thrown');
    } catch (e) {
      expect(e.code).to.equal(400);
      expect(e.message).to.include('amount');
    }
  });

  it('should return only active orders via API', async () => {
    const response = await cds.test.get('/odata/v4/OrderService/Orders?$filter=status eq \'ACTIVE\'');
    expect(response.status).to.equal(200);
    response.data.value.forEach(order => {
      expect(order.status).to.equal('ACTIVE');
    });
  });
});
```

### Pattern 5: OPA5 UI5 Integration Test

```javascript
sap.ui.define([
  "sap/ui/test/opaQunit",
  "sap/ui/test/Opa5",
  "sap/ui/test/matchers/Properties",
  "sap/ui/test/actions/Press"
], function (opaTest, Opa5, Properties, Press) {
  "use strict";

  opaTest("Should display order list", function (Given, When, Then) {
    Given.iStartMyApp();
    Then.onTheOrderList.iShouldSeeTheTable();
  });

  opaTest("Should navigate to detail on press", function (Given, When, Then) {
    When.onTheOrderList.iPressOnFirstItem();
    Then.onTheOrderDetail.iShouldSeeTheObjectHeader();
    Then.iTeardownMyApp();
  });

  Opa5.createPageObjects({
    onTheOrderList: {
      actions: {
        iPressOnFirstItem: function () {
          return this.waitFor({
            controlType: "sap.m.ColumnListItem",
            matchers: new Properties({ type: "Navigation" }),
            actions: new Press(),
            success: function () { Opa5.assert.ok(true, "Pressed first item"); }
          });
        }
      },
      assertions: {
        iShouldSeeTheTable: function () {
          return this.waitFor({
            id: "orderTable",
            success: function () { Opa5.assert.ok(true, "Table visible"); }
          });
        }
      }
    }
  });
});
```

## Error Catalog

| Error | Context | Root Cause | Fix |
|-------|---------|------------|-----|
| `CX_AUNIT_ASSERT_FAILED` | ABAP Unit assertion | Expected ≠ actual value | Check test data setup; verify production logic |
| `CL_OSQL_TEST_ENVIRONMENT CREATE failed` | SQL double | Table name wrong or not accessible | Use exact DB table name (not CDS entity name) |
| `CDS test: no data returned` | CDS test double | Redirection not enabled or wrong entity | Call `enable_double_redirection( )` after create |
| `cds.test timeout` | CAP test | Service startup slow or DB connection issue | Increase timeout; check `cds.requires` for test profile |
| `OPA5 waitFor timeout` | UI5 test | Control not rendered or wrong matcher | Increase timeout; verify control ID or matcher config |
| `ATC: check cannot be suppressed` | ATC exemption | Priority-1 findings block transport | Fix the code; P1 findings cannot be exempted |

## Performance Tips

1. **Test isolation** — Each test method independent; use `setup` for fresh state
2. **`RISK LEVEL HARMLESS`** — Fastest execution; no DB rollback overhead
3. **Minimize test doubles** — Only double external dependencies; test real logic
4. **Parallel ATC** — Run ATC checks in parallel in CI; each object type independently
5. **CAP test profiles** — Use `[test]` profile in `.cdsrc.json` with SQLite for speed
6. **OPA5 `autoWait`** — Enable `autoWait: true` in OPA config to avoid flaky tests
7. **Test data builders** — Create helper methods for test data; reduce duplication across test methods

## Gotchas

- **ABAP test double limitations**: Only works with interfaces, not concrete classes — design for dependency injection
- **SQL double scope**: `CL_OSQL_TEST_ENVIRONMENT` doubles apply to the entire test class, not per method — use `clear_doubles( )` in setup
- **CDS entity vs. DB table**: `CL_CDS_TEST_ENVIRONMENT` takes the CDS entity name; `CL_OSQL_TEST_ENVIRONMENT` takes the DB table name
- **ATC in ABAP Cloud**: Some classic ATC checks don't apply; ABAP Cloud has its own check set
- **OPA5 async pitfalls**: All OPA assertions are async; never use synchronous checks after `waitFor`
- **CAP test DB**: By default `cds test` uses in-memory SQLite; HANA-specific SQL won't work — use `[test]` profile with HANA for integration tests
