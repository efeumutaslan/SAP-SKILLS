---
name: sap-fiori-testing
description: |
  SAP Fiori and UI5 testing, accessibility, and modern UI skill. Use when: writing wdi5
  (WebdriverIO + UI5) end-to-end tests, OPA5 integration tests, UIVeri5 visual regression
  tests, implementing WCAG 2.1 accessibility in Fiori apps, using UI5 Web Components,
  migrating UI5 JavaScript to TypeScript, testing Fiori Elements apps, or setting up
  UI test automation in CI/CD pipelines. Extends base sapui5/fiori-tools skills.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Fiori Testing, Accessibility & Modern UI

## Related Skills
- `sap-testing-quality` — Cross-cutting SAP testing strategy
- `sap-devops-cicd` — UI test automation in pipelines
- `sap-build-apps` — Alternative low-code UI approach

## Quick Start

**Choose your test framework:**

| Framework | Level | Speed | Best For |
|-----------|-------|-------|----------|
| **QUnit** | Unit | Fast | Controller logic, formatters |
| **OPA5** | Integration | Medium | UI interaction flows, navigation |
| **wdi5** | E2E | Slow | Full app testing, cross-app |
| **UIVeri5** | Visual/E2E | Slow | Visual regression, screenshots |

**Quick wdi5 setup:**

```bash
npm init wdi5@latest
# Follow prompts: select UI5 app, choose test runner
# Generates: wdio.conf.js + test structure
```

## Core Concepts

### UI5 Test Pyramid
```
         /\
        /  \     E2E (wdi5/UIVeri5)
       /    \    - Full app in browser
      /------\   - Real backend or mock server
     /        \
    / OPA5     \ Integration
   /   Tests    \ - UI interaction + navigation
  /--------------\ - Mock server for data
 /                \
/ QUnit Unit Tests \ Unit
/                    \ - Pure logic, no DOM
/____________________\
```

### wdi5 Architecture
```
Test Script ──► wdi5 Bridge ──► UI5 Control API
    │               │               │
 WebdriverIO    Injects JS      sap.ui.test.*
 (Selenium/     into browser    control selectors
  Playwright)
```

### OPA5 Key Concepts
| Concept | Role | Example |
|---------|------|---------|
| **Page Object** | Encapsulates page interactions | `onTheMainPage.iClickCreate()` |
| **Journey** | Test scenario (sequence of actions) | `opaTest("Create order", ...)` |
| **Arrangement** | Setup state | `Given.iStartMyApp()` |
| **Action** | User interaction | `When.onTheList.iSelectItem("001")` |
| **Assertion** | Verify outcome | `Then.onTheDetail.iSeeTitle("Order 001")` |

## Common Patterns

### Pattern 1: wdi5 Test with UI5 Selectors

```javascript
// test/e2e/specs/order.test.js
const { wdi5 } = require('wdio-ui5-service');

describe('Order Management', () => {
  before(async () => {
    await browser.url('#/Orders');
    await browser.asControl({
      selector: { controlType: 'sap.m.Page', viewName: 'orders.List' }
    });
  });

  it('should display order list', async () => {
    const table = await browser.asControl({
      selector: {
        controlType: 'sap.m.Table',
        viewName: 'orders.List',
        id: 'orderTable'
      }
    });
    const items = await table.getItems();
    expect(items.length).toBeGreaterThan(0);
  });

  it('should create new order', async () => {
    // Click Create button
    const createBtn = await browser.asControl({
      selector: {
        controlType: 'sap.m.Button',
        viewName: 'orders.List',
        properties: { text: 'Create' }
      }
    });
    await createBtn.press();

    // Fill form
    const customerInput = await browser.asControl({
      selector: {
        controlType: 'sap.m.Input',
        viewName: 'orders.Create',
        id: 'customerInput'
      }
    });
    await customerInput.setValue('CUST001');

    const amountInput = await browser.asControl({
      selector: {
        controlType: 'sap.m.Input',
        viewName: 'orders.Create',
        id: 'amountInput'
      }
    });
    await amountInput.setValue('1500.00');

    // Save
    const saveBtn = await browser.asControl({
      selector: {
        controlType: 'sap.m.Button',
        viewName: 'orders.Create',
        properties: { type: 'Emphasized' }
      }
    });
    await saveBtn.press();

    // Verify success message
    const msgStrip = await browser.asControl({
      selector: {
        controlType: 'sap.m.MessageStrip',
        properties: { type: 'Success' }
      }
    });
    const text = await msgStrip.getText();
    expect(text).toContain('created successfully');
  });
});
```

```javascript
// wdio.conf.js
exports.config = {
  specs: ['./test/e2e/specs/**/*.test.js'],
  maxInstances: 1,
  capabilities: [{
    browserName: 'chrome',
    'goog:chromeOptions': {
      args: ['--headless', '--no-sandbox', '--disable-gpu']
    }
  }],
  baseUrl: 'http://localhost:8080',
  services: ['ui5'],
  ui5: {
    path: { webapp: 'webapp' },
    url: 'http://localhost:8080/index.html'
  },
  framework: 'mocha',
  mochaOpts: { timeout: 60000 }
};
```

### Pattern 2: OPA5 Integration Test

```javascript
// test/integration/pages/OrderList.js
sap.ui.define([
  'sap/ui/test/Opa5',
  'sap/ui/test/actions/Press',
  'sap/ui/test/actions/EnterText',
  'sap/ui/test/matchers/Properties',
  'sap/ui/test/matchers/AggregationLengthEquals'
], function (Opa5, Press, EnterText, Properties, AggregationLengthEquals) {
  'use strict';

  Opa5.createPageObjects({
    onTheOrderListPage: {
      actions: {
        iSearchFor: function (sQuery) {
          return this.waitFor({
            id: 'searchField',
            viewName: 'orders.List',
            actions: new EnterText({ text: sQuery }),
            errorMessage: 'Search field not found'
          });
        },
        iPressCreateButton: function () {
          return this.waitFor({
            controlType: 'sap.m.Button',
            viewName: 'orders.List',
            matchers: new Properties({ text: 'Create' }),
            actions: new Press(),
            errorMessage: 'Create button not found'
          });
        },
        iSelectFirstItem: function () {
          return this.waitFor({
            controlType: 'sap.m.ColumnListItem',
            viewName: 'orders.List',
            actions: new Press(),
            errorMessage: 'No list items found'
          });
        }
      },
      assertions: {
        iShouldSeeTheTable: function () {
          return this.waitFor({
            id: 'orderTable',
            viewName: 'orders.List',
            success: function () { Opa5.assert.ok(true, 'Table is visible'); },
            errorMessage: 'Table not found'
          });
        },
        theTableShouldHaveEntries: function (iCount) {
          return this.waitFor({
            id: 'orderTable',
            viewName: 'orders.List',
            matchers: new AggregationLengthEquals({
              name: 'items', length: iCount
            }),
            success: function () {
              Opa5.assert.ok(true, 'Table has ' + iCount + ' entries');
            },
            errorMessage: 'Table does not have ' + iCount + ' entries'
          });
        }
      }
    }
  });
});
```

```javascript
// test/integration/OrderJourney.js
sap.ui.define([
  'sap/ui/test/opaQunit',
  './pages/OrderList'
], function (opaTest) {
  'use strict';

  QUnit.module('Order Management');

  opaTest('Should see order list on start', function (Given, When, Then) {
    Given.iStartMyApp();
    Then.onTheOrderListPage.iShouldSeeTheTable();
  });

  opaTest('Should filter orders by search', function (Given, When, Then) {
    When.onTheOrderListPage.iSearchFor('CUST001');
    Then.onTheOrderListPage.theTableShouldHaveEntries(3);
  });

  opaTest('Should navigate to create page', function (Given, When, Then) {
    When.onTheOrderListPage.iPressCreateButton();
    Then.onTheCreatePage.iShouldSeeTheForm();
    Then.iTeardownMyApp();
  });
});
```

### Pattern 3: Fiori Elements OPA5 Test

```javascript
// test/integration/FEListReportJourney.js
sap.ui.define([
  'sap/ui/test/opaQunit',
  'sap/fe/test/ListReport',
  'sap/fe/test/ObjectPage'
], function (opaTest, ListReport, ObjectPage) {
  'use strict';

  var oListReport = new ListReport({ entitySet: 'Orders' });
  var oObjectPage = new ObjectPage({ entitySet: 'Orders' });

  QUnit.module('Fiori Elements - List Report');

  opaTest('Table loads with data', function (Given, When, Then) {
    Given.iStartMyFLPApp('orders-manage');
    Then.onTheListReport.iSeeTheTable();
    Then.onTheListReport.iCheckRows(10);
  });

  opaTest('Filter by status', function (Given, When, Then) {
    When.onTheListReport.iOpenFilterBar();
    When.onTheListReport.iFilterByField('Status', 'Open');
    When.onTheListReport.iExecuteFilter();
    Then.onTheListReport.iCheckRows(5);
  });

  opaTest('Navigate to detail', function (Given, When, Then) {
    When.onTheListReport.iPressRow(0);
    Then.onTheObjectPage.iSeeThisPage();
    Then.onTheObjectPage.iSeeHeaderTitle('ORD-001');
    Then.iTeardownMyApp();
  });
});
```

### Pattern 4: WCAG 2.1 Accessibility Checklist

```javascript
// Accessibility patterns for Fiori apps

// 1. Labels for all inputs
// BAD:
new sap.m.Input({ placeholder: "Enter name" });
// GOOD:
new sap.m.Label({ text: "Customer Name", labelFor: "nameInput" });
new sap.m.Input({ id: "nameInput" });

// 2. ARIA for custom controls
new sap.m.GenericTile({
  header: "Revenue",
  ariaLabel: "Revenue tile showing 1.5 million euros",
  press: function() { /* navigate */ }
});

// 3. High contrast support — use semantic colors
// BAD: custom CSS colors
// GOOD: use UI5 semantic classes
// .sapMObjStatusActive (standard active state)
// sap.ui.core.IconColor.Positive / Negative / Critical

// 4. Keyboard navigation
// Ensure all interactive elements are reachable via Tab
// Use sap.m.Table not custom HTML for data grids
// Test with screen reader (JAWS, NVDA, VoiceOver)

// 5. Color-independent information
// BAD: status shown only by color
// GOOD: status shown by color + icon + text
new sap.m.ObjectStatus({
  text: "Approved",
  state: "Success",
  icon: "sap-icon://accept"
});
```

### Pattern 5: UI5 TypeScript Migration

```typescript
// webapp/controller/OrderList.controller.ts
import Controller from "sap/ui/core/mvc/Controller";
import JSONModel from "sap/ui/model/json/JSONModel";
import Filter from "sap/ui/model/Filter";
import FilterOperator from "sap/ui/model/FilterOperator";
import MessageToast from "sap/m/MessageToast";
import Event from "sap/ui/base/Event";
import Table from "sap/m/Table";
import ListBinding from "sap/ui/model/ListBinding";

/**
 * @namespace orders.controller
 */
export default class OrderList extends Controller {
  public onInit(): void {
    const oViewModel = new JSONModel({
      busy: false,
      orderCount: 0
    });
    this.getView()?.setModel(oViewModel, "view");
  }

  public onSearch(oEvent: Event): void {
    const sQuery = (oEvent.getParameter("query") as string) || "";
    const aFilters: Filter[] = [];

    if (sQuery) {
      aFilters.push(new Filter("CustomerName", FilterOperator.Contains, sQuery));
    }

    const oTable = this.byId("orderTable") as Table;
    const oBinding = oTable.getBinding("items") as ListBinding;
    oBinding.filter(aFilters);
  }

  public onCreatePress(): void {
    this.getOwnerComponent()?.getRouter().navTo("create");
  }

  public async onRefresh(): Promise<void> {
    const oTable = this.byId("orderTable") as Table;
    const oBinding = oTable.getBinding("items") as ListBinding;

    try {
      await oBinding.requestRefresh();
      MessageToast.show("Data refreshed");
    } catch (error) {
      MessageToast.show("Refresh failed");
    }
  }
}
```

```json
// tsconfig.json for UI5 TypeScript
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "node",
    "skipLibCheck": true,
    "allowJs": true,
    "strict": true,
    "strictNullChecks": true,
    "baseUrl": ".",
    "paths": {
      "orders/*": ["webapp/*"]
    },
    "types": ["@openui5/types"]
  },
  "include": ["webapp/**/*.ts"]
}
```

### Pattern 6: UI5 Web Components Integration

```html
<!-- Using UI5 Web Components in standalone/React/Vue apps -->
<script type="module">
  import "@ui5/webcomponents/dist/Button.js";
  import "@ui5/webcomponents/dist/Table.js";
  import "@ui5/webcomponents/dist/Input.js";
  import "@ui5/webcomponents-fiori/dist/ShellBar.js";
  import "@ui5/webcomponents-fiori/dist/SideNavigation.js";
</script>

<ui5-shellbar primary-title="Order Management" show-notifications>
</ui5-shellbar>

<ui5-table>
  <ui5-table-column slot="columns">
    <ui5-label>Order ID</ui5-label>
  </ui5-table-column>
  <ui5-table-column slot="columns">
    <ui5-label>Customer</ui5-label>
  </ui5-table-column>
  <ui5-table-row>
    <ui5-table-cell><ui5-label>ORD-001</ui5-label></ui5-table-cell>
    <ui5-table-cell><ui5-label>Acme Corp</ui5-label></ui5-table-cell>
  </ui5-table-row>
</ui5-table>
```

```jsx
// React + UI5 Web Components
import { ShellBar, Table, TableColumn, TableRow, TableCell } from '@ui5/webcomponents-react';

function OrderList({ orders }) {
  return (
    <>
      <ShellBar primaryTitle="Order Management" />
      <Table columns={
        <>
          <TableColumn><span>Order ID</span></TableColumn>
          <TableColumn><span>Customer</span></TableColumn>
          <TableColumn><span>Amount</span></TableColumn>
        </>
      }>
        {orders.map(order => (
          <TableRow key={order.id}>
            <TableCell><span>{order.id}</span></TableCell>
            <TableCell><span>{order.customer}</span></TableCell>
            <TableCell><span>{order.amount}</span></TableCell>
          </TableRow>
        ))}
      </Table>
    </>
  );
}
```

## Error Catalog

| Error | Context | Root Cause | Fix |
|-------|---------|------------|-----|
| `wdi5: Control not found` | wdi5 selector | Wrong controlType or viewName | Use UI5 Inspector to get correct selector |
| `OPA5: Timeout` | waitFor expired | Element not rendered in time | Increase `timeout`; check if element is conditional |
| `OPA5: Ambiguous match` | Multiple controls match | Selector too broad | Add `id`, `viewName`, or more specific `matchers` |
| `TS2307: Cannot find module` | TypeScript import | Missing `@openui5/types` or wrong path | Install types: `npm i -D @openui5/types` |
| `wdi5: Session not created` | Browser start failed | ChromeDriver version mismatch | Update chromedriver or use `services: ['chromedriver']` |
| `FE test: Page not found` | Fiori Elements OPA | Wrong entitySet or app ID | Check `manifest.json` routing config |
| `a11y: Missing label` | Accessibility audit | Input without associated label | Add `sap.m.Label` with `labelFor` |
| `a11y: Low contrast` | Color contrast check | Custom theme colors too similar | Use SAP theme parameters; test with High Contrast theme |

## Performance Tips

1. **OPA5 over wdi5 for UI logic** — OPA5 runs in-browser (no Selenium overhead); use wdi5 only for cross-app/E2E
2. **Mock server for OPA5** — Use `sap/ui/core/util/MockServer` to eliminate backend dependency
3. **Headless browser** — Run wdi5/UIVeri5 headless in CI/CD (Chrome `--headless`)
4. **Parallel OPA5 suites** — Split OPA test files by module; run in parallel with Karma
5. **Selective test runs** — Use `QUnit.module` filtering to run only changed test suites
6. **UI5 TypeScript** — Compiler catches errors at build time; reduces runtime debugging

## Gotchas

- **wdi5 vs UIVeri5**: wdi5 is community-maintained (active), UIVeri5 is SAP-maintained (slower updates)
- **OPA5 auto-wait**: OPA5 waits for UI5 rendering automatically; don't add manual `setTimeout`
- **Fiori Elements tests**: Use `sap/fe/test/*` page objects, not custom selectors for FE apps
- **TypeScript types**: `@openui5/types` (open-source) vs `@sapui5/types` (requires SAP license)
- **Web Components ≠ UI5**: `@ui5/webcomponents` is framework-agnostic; different API from `sap.m.*` controls
- **Accessibility testing**: Automated tools catch ~30% of issues; manual screen reader testing is essential
