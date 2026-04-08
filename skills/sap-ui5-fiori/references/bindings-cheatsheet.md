# SAPUI5 Bindings Cheatsheet

Complete reference for all UI5 binding types and syntax.

## Table of Contents

- [Binding Types](#binding-types)
- [Property Binding](#property-binding)
- [Element (Context) Binding](#element-context-binding)
- [Aggregation (List) Binding](#aggregation-list-binding)
- [Expression Binding](#expression-binding)
- [Composite Binding](#composite-binding)
- [Named Models](#named-models)
- [Formatters](#formatters)
- [Formatters vs Expressions](#formatters-vs-expressions)
- [Binding Modes](#binding-modes)
- [Filters and Sorters](#filters-and-sorters)
- [Parameters (OData v4)](#parameters-odata-v4)
- [Runtime Binding API](#runtime-binding-api)

## Binding Types

| Type | Binds | Example |
|------|-------|---------|
| **Property** | Single value | `text="{Name}"` |
| **Element (context)** | An entity instance | `binding="{/Products('HT-1001')}"` |
| **Aggregation (list)** | List/collection | `items="{/Products}"` |
| **Expression** | Computed value | `text="{= ${Price} > 100 ? 'high' : 'low' }"` |
| **Composite** | Multiple values | `text="{parts: [{path: 'A'}, {path: 'B'}]}"` |

## Property Binding

Simplest form — bind a control property to a model path:

```xml
<Text text="{Name}" />
<Input value="{Email}" />
<CheckBox selected="{IsActive}" />
```

Absolute path (starts with `/`):
```xml
<Text text="{/currentUser/name}" />
```

Relative path (uses current binding context):
```xml
<Form binding="{/Products('HT-1001')}">
  <Text text="{Name}" />        <!-- resolves to /Products('HT-1001')/Name -->
  <Text text="{Price}" />       <!-- resolves to /Products('HT-1001')/Price -->
</Form>
```

## Element (Context) Binding

Bind an entity context to a container, then children inherit it:

```xml
<Panel binding="{/Employees('E001')}">
  <Text text="{FirstName}" />
  <Text text="{LastName}" />
  <Text text="{Department/Name}" />  <!-- navigation -->
</Panel>
```

Programmatic:
```javascript
oPanel.bindElement("/Employees('E001')");
oPanel.bindElement({ path: "/Employees('E001')", parameters: { $expand: "Department" } });
```

## Aggregation (List) Binding

Bind a collection to an aggregation (e.g., `items`, `rows`, `cells`):

```xml
<List items="{/Products}">
  <StandardListItem title="{Name}" description="{Category}" />
</List>
```

Template-based (explicit):
```xml
<Table items="{
  path: '/Products',
  sorter: { path: 'Name' },
  filters: [{ path: 'Active', operator: 'EQ', value1: true }],
  parameters: { $count: true, $expand: 'Supplier' }
}">
  <columns>
    <Column><Text text="Name" /></Column>
    <Column><Text text="Supplier" /></Column>
  </columns>
  <items>
    <ColumnListItem>
      <cells>
        <Text text="{Name}" />
        <Text text="{Supplier/Name}" />
      </cells>
    </ColumnListItem>
  </items>
</Table>
```

## Expression Binding

Compute values inline without a formatter function:

```xml
<!-- Comparison -->
<Text text="{= ${Price} > 100 ? 'Expensive' : 'Cheap' }" />

<!-- Arithmetic -->
<Text text="{= ${Quantity} * ${UnitPrice} }" />

<!-- String concatenation -->
<Text text="{= 'Hello, ' + ${FirstName} + ' ' + ${LastName} }" />

<!-- Logical -->
<Button enabled="{= ${IsActive} && !${IsLocked} }" />

<!-- Null/undefined checks -->
<Text text="{= ${Description} || 'No description' }" />

<!-- Function calls -->
<Text text="{= ${Name}.toUpperCase() }" />

<!-- Format with odata types -->
<Text text="{= format.currency(${Price}, ${CurrencyCode}) }" />
```

Use `$` only for the first reference in expressions:
- ✅ `{= ${A} + ${B} }`
- ❌ `{= ${A} + B }` (B is undefined)

## Composite Binding

Combine multiple bindings into one property:

```xml
<!-- Multiple parts → formatter function -->
<Text text="{
  parts: [
    { path: 'FirstName' },
    { path: 'LastName' }
  ],
  formatter: '.formatter.fullName'
}" />

<!-- Typed composite (currency) -->
<Text text="{
  parts: [{ path: 'Price' }, { path: 'CurrencyCode' }],
  type: 'sap.ui.model.type.Currency',
  formatOptions: { showMeasure: false }
}" />
```

## Named Models

When you have multiple models, prefix the path with the model name and `>`:

```xml
<!-- Default model (no prefix) -->
<Text text="{/Products/0/Name}" />

<!-- i18n model -->
<Button text="{i18n>buttonSave}" />

<!-- Device model -->
<Panel visible="{device>/system/desktop}" />

<!-- Custom view model -->
<Input busy="{viewModel>/busy}" />

<!-- JSON model named 'data' -->
<Text text="{data>/user/email}" />
```

## Formatters

```javascript
// model/formatter.js
sap.ui.define([], function () {
  "use strict";
  return {
    statusText: function (sStatus) {
      switch (sStatus) {
        case "A": return "Active";
        case "I": return "Inactive";
        default: return "Unknown";
      }
    },

    // Multi-part formatter — receives multiple values
    fullName: function (sFirst, sLast) {
      return `${sFirst || ''} ${sLast || ''}`.trim();
    },

    // Formatter with access to the controller's i18n
    i18nStatus: function (sStatus) {
      const oBundle = this.getView().getModel("i18n").getResourceBundle();
      return oBundle.getText("status" + sStatus);
    }
  };
});
```

Attach to controller:
```javascript
// Controller.js
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "my/app/model/formatter"
], function (Controller, formatter) {
  return Controller.extend("my.app.controller.Main", {
    formatter: formatter,  // Now available as .formatter.xxx in XML
    onInit: function () { /* ... */ }
  });
});
```

Use in XML:
```xml
<Text text="{path: 'Status', formatter: '.formatter.statusText'}" />
```

## Formatters vs Expressions

| Use case | Choose |
|----------|--------|
| Simple comparison, arithmetic | Expression |
| Complex logic, multiple branches | Formatter |
| i18n translation | Formatter (expressions can't access i18n cleanly) |
| Unit tests required | Formatter (can be tested in isolation) |
| One-off inline | Expression |
| Reused in many places | Formatter |

## Binding Modes

```xml
<Input value="{path: 'Name', mode: 'TwoWay'}" />
<Text text="{path: 'Name', mode: 'OneWay'}" />
<Text text="{path: 'Name', mode: 'OneTime'}" />
```

| Mode | Direction | Use case |
|------|-----------|----------|
| `OneWay` | Model → View | Display-only |
| `TwoWay` | Model ↔ View | Editable forms |
| `OneTime` | Model → View once | Static labels |
| `Default` | Model's default mode | Usually TwoWay for ODataModel |

Set the default per model in manifest.json:
```json
"models": {
  "": { "type": "sap.ui.model.odata.v4.ODataModel",
        "settings": { "operationMode": "Server" },
        "defaultBindingMode": "OneWay" }
}
```

## Filters and Sorters

### Filters
```javascript
const oFilter = new sap.ui.model.Filter({
  path: "Price",
  operator: sap.ui.model.FilterOperator.GT,
  value1: 100
});

// Multiple filters (AND)
const aFilters = [
  new sap.ui.model.Filter("Category", "EQ", "Electronics"),
  new sap.ui.model.Filter("Price", "LT", 500)
];

// OR combination
const oOrFilter = new sap.ui.model.Filter({
  filters: [
    new sap.ui.model.Filter("Category", "EQ", "Electronics"),
    new sap.ui.model.Filter("Category", "EQ", "Furniture")
  ],
  and: false
});

// Apply to list binding
oList.getBinding("items").filter(aFilters);
```

### Filter operators
| Operator | Matches |
|----------|---------|
| `EQ` | Equal |
| `NE` | Not equal |
| `LT`, `LE` | Less than / less or equal |
| `GT`, `GE` | Greater than / greater or equal |
| `BT` | Between (needs `value1` and `value2`) |
| `Contains` | Substring |
| `StartsWith`, `EndsWith` | String prefix/suffix |
| `Any`, `All` | For navigation collections (OData v4) |

### Sorters
```javascript
const oSorter = new sap.ui.model.Sorter("Name", false); // path, descending?
oList.getBinding("items").sort([oSorter]);

// Group by a property
const oGroupSorter = new sap.ui.model.Sorter("Category", false, true); // group: true
```

## Parameters (OData v4)

```xml
<List items="{
  path: '/Products',
  parameters: {
    $count: true,
    $select: 'ID,Name,Price',
    $expand: {
      'Supplier': { $select: 'Name,Country' },
      'Category': {}
    },
    $filter: 'Price gt 100',
    $orderby: 'Name asc'
  }
}">
```

Common parameters:
- `$count` — include `@odata.count`
- `$select` — limit columns (reduces payload)
- `$expand` — include related entities
- `$filter` — server-side filtering
- `$orderby` — server-side sorting
- `$top`, `$skip` — paging
- `$search` — full-text search (if service supports it)

## Runtime Binding API

```javascript
// Get a binding
const oBinding = this.byId("myList").getBinding("items");

// Filter programmatically
oBinding.filter([new sap.ui.model.Filter("Name", "Contains", "test")]);

// Sort
oBinding.sort([new sap.ui.model.Sorter("Name")]);

// Refresh (re-fetch from server)
oBinding.refresh();

// Resume (if suspended)
oBinding.resume();

// Change parameters (v4)
oBinding.changeParameters({ $filter: "Category eq 'Electronics'" });

// Read single value from model
const sName = this.getView().getModel().getProperty("/Products('HT-1001')/Name");

// Update (will trigger PATCH in OData v4)
this.getView().getModel().setProperty("/Products('HT-1001')/Name", "New Name");
```

## Gotchas

- **Relative paths need a binding context** — without `binding="..."` on a parent, relative paths resolve to undefined.
- **`{` in text literals** needs escaping: `\\{` or use expression binding with a string.
- **Two-way binding on formatted values** — formatters are one-way by default. Use a custom `Type` with `parseValue` for two-way.
- **Binding contexts are async in v4** — check `oContext.getBoundContext()` or wait for `dataReceived` event before reading.
- **`$expand` in element binding** — parameters go on the `parameters` object, not as a query string.
- **Model not found** — if you use `{modelName>path}` and the model isn't set, the binding silently fails. Check `this.getView().getModel("modelName")`.
