---
name: sap-ui5-fiori
description: >
  SAPUI5 and Fiori application development skill. Use when building Fiori apps, writing XML views,
  creating UI5 controllers, binding OData models, configuring manifest.json, implementing routing,
  using Fiori Elements (LROP/OVP/ALP), or working with SAP Fiori design guidelines. If the user
  mentions SAPUI5, Fiori, XML view, UI5 controller, manifest, Fiori Elements, sap.m, sap.ui.table,
  JSONModel, ODataModel, or Fiori launchpad, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-04-08"
---

# SAPUI5 and Fiori Application Development

## Related Skills
- `sap-fiori-testing` — OPA5, wdi5, accessibility testing for the apps built here
- `sap-odata` — OData v2/v4 service design and consumption (the backend for most Fiori apps)
- `sap-rap-comprehensive` — RAP backends that auto-generate OData for UI5 consumption
- `sap-cap-advanced` — CAP backends with CDS-based OData services
- `sap-build-apps` — Low-code alternative when full UI5 is overkill

## Quick Start

**Scaffold a new freestyle UI5 app (Fiori Tools):**
```bash
npm install -g @sap/generator-fiori
yo @sap/fiori
# Select: SAPUI5 freestyle → Basic → OData V4 service → project details
```

**Scaffold a Fiori Elements app (zero-code UI):**
```bash
yo @sap/fiori
# Select: SAPUI5 Fiori Elements → List Report Object Page (LROP)
```

**Run locally with live-reload:**
```bash
npm start                     # Starts ui5 serve with local OData mock or proxy
```

**Build for deployment:**
```bash
npm run build                 # Produces dist/ folder
npm run deploy                # Deploys to ABAP, CF, or HTML5 repo
```

## Core Concepts

### MVC architecture
```
app/
├── webapp/
│   ├── Component.js          # Component: root, manifest, models, router
│   ├── manifest.json         # App descriptor (routes, models, data sources)
│   ├── view/                 # XML views (declarative UI)
│   │   ├── App.view.xml
│   │   ├── Worklist.view.xml
│   │   └── Object.view.xml
│   ├── controller/           # Controller logic (event handlers, business logic)
│   │   ├── App.controller.js
│   │   ├── Worklist.controller.js
│   │   └── Object.controller.js
│   ├── model/                # Formatters, grouping, custom models
│   │   └── formatter.js
│   ├── i18n/                 # Translations
│   │   └── i18n.properties
│   ├── css/                  # Custom styles
│   └── test/                 # QUnit/OPA5 tests
├── ui5.yaml                  # UI5 tooling config
└── package.json
```

### Models (critical to understand)

| Model | Use case | Binding syntax |
|-------|----------|----------------|
| `JSONModel` | Client-side state, mock data, view state | `{/path/to/value}` |
| `ODataModel` (v4) | Primary for SAPUI5 + modern SAP backends | `{propertyName}` or `{BindingPath}` |
| `ODataModel` (v2) | Legacy OData services, Gateway services | `{propertyName}` |
| `ResourceModel` | i18n texts from .properties files | `{i18n>textKey}` |
| `DeviceModel` | Device info (phone/tablet/desktop, orientation) | `{device>/system/phone}` |

### Binding modes
```xml
<!-- Property binding: single value -->
<Text text="{Name}" />

<!-- Element binding: bind a context (entity) to a control -->
<Form binding="{/Products('HT-1001')}">

<!-- Aggregation binding: list of items -->
<List items="{/Products}">
  <StandardListItem title="{Name}" description="{Category}" />
</List>

<!-- Expression binding: computed values -->
<ObjectStatus text="{= ${Price} > 100 ? 'Expensive' : 'Cheap' }" />

<!-- i18n binding -->
<Button text="{i18n>buttonSave}" />
```

### Routing (manifest.json)
```json
"routing": {
  "config": {
    "routerClass": "sap.m.routing.Router",
    "viewType": "XML",
    "viewPath": "my.app.view",
    "controlId": "app",
    "controlAggregation": "pages"
  },
  "routes": [
    { "name": "worklist", "pattern": "", "target": "worklist" },
    { "name": "object", "pattern": "Products/{productId}", "target": "object" }
  ],
  "targets": {
    "worklist": { "viewName": "Worklist" },
    "object":   { "viewName": "Object" }
  }
}
```

Navigate from a controller:
```javascript
this.getOwnerComponent().getRouter().navTo("object", { productId: "HT-1001" });
```

## Common Patterns

### Pattern 1: Basic controller skeleton
```javascript
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/m/MessageToast"
], function (Controller, JSONModel, MessageToast) {
  "use strict";

  return Controller.extend("my.app.controller.Worklist", {

    onInit: function () {
      const oViewModel = new JSONModel({ busy: false, delay: 0 });
      this.getView().setModel(oViewModel, "viewModel");
    },

    onRefresh: function () {
      const oList = this.byId("productsList");
      oList.getBinding("items").refresh();
    },

    onItemPress: function (oEvent) {
      const sPath = oEvent.getSource().getBindingContext().getPath();
      const sProductId = sPath.match(/'([^']+)'/)[1];
      this.getOwnerComponent().getRouter().navTo("object", { productId: sProductId });
    },

    onSearch: function (oEvent) {
      const sQuery = oEvent.getParameter("query");
      const oBinding = this.byId("productsList").getBinding("items");
      const aFilters = sQuery ? [new sap.ui.model.Filter("Name", "Contains", sQuery)] : [];
      oBinding.filter(aFilters);
    }
  });
});
```

### Pattern 2: Worklist XML view (list + search + pull-to-refresh)
```xml
<mvc:View
  controllerName="my.app.controller.Worklist"
  xmlns="sap.m"
  xmlns:mvc="sap.ui.core.mvc">
  <Page title="{i18n>worklistTitle}">
    <subHeader>
      <Toolbar>
        <SearchField width="100%" search=".onSearch" />
      </Toolbar>
    </subHeader>
    <content>
      <List
        id="productsList"
        items="{path: '/Products', parameters: {$count: true}}"
        growing="true"
        growingThreshold="20"
        growingScrollToLoad="true">
        <ObjectListItem
          title="{Name}"
          number="{
            parts: [{path: 'Price'}, {path: 'CurrencyCode'}],
            type: 'sap.ui.model.type.Currency',
            formatOptions: {showMeasure: false}
          }"
          numberUnit="{CurrencyCode}"
          type="Navigation"
          press=".onItemPress">
          <attributes>
            <ObjectAttribute text="{Category}" />
          </attributes>
        </ObjectListItem>
      </List>
    </content>
  </Page>
</mvc:View>
```

### Pattern 3: Fiori Elements — annotation-driven LROP
With Fiori Elements you write **no controller code**. The UI is generated from CDS annotations or `manifest.json` + `metadata.xml`.

```cds
// Backend annotations (CAP/CDS)
annotate Products with @(
  UI.LineItem: [
    { Value: ID },
    { Value: Name },
    { Value: Category },
    { Value: Price }
  ],
  UI.HeaderInfo: {
    TypeName: 'Product',
    TypeNamePlural: 'Products',
    Title: { Value: Name }
  },
  UI.SelectionFields: [ Category, Price ]
);
```

The UI5 app's `manifest.json` references `sap.fe.templates.ListReport` and the OData service — that's it. The app auto-renders a filter bar, table, and detail page.

### Pattern 4: Fragments (reusable UI chunks)
```xml
<!-- view/Dialog.fragment.xml -->
<core:FragmentDefinition xmlns="sap.m" xmlns:core="sap.ui.core">
  <Dialog title="{i18n>dialogTitle}">
    <content>
      <Input value="{/newValue}" />
    </content>
    <beginButton>
      <Button text="OK" press=".onDialogOk" />
    </beginButton>
    <endButton>
      <Button text="Cancel" press=".onDialogCancel" />
    </endButton>
  </Dialog>
</core:FragmentDefinition>
```

```javascript
// Controller
onOpenDialog: async function () {
  if (!this._oDialog) {
    this._oDialog = await this.loadFragment({ name: "my.app.view.Dialog" });
  }
  this._oDialog.open();
}
```

### Pattern 5: manifest.json essentials
```json
{
  "_version": "1.58.0",
  "sap.app": {
    "id": "my.app",
    "type": "application",
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata/sap/ZMY_SERVICE/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  },
  "sap.ui5": {
    "dependencies": {
      "minUI5Version": "1.120.0",
      "libs": { "sap.m": {}, "sap.ui.core": {}, "sap.f": {} }
    },
    "models": {
      "i18n": { "type": "sap.ui.model.resource.ResourceModel",
                "settings": { "bundleName": "my.app.i18n.i18n" } },
      "": {
        "dataSource": "mainService",
        "preload": true,
        "settings": {
          "synchronizationMode": "None",
          "operationMode": "Server",
          "autoExpandSelect": true,
          "earlyRequests": true
        }
      }
    },
    "routing": { /* ... see Routing section */ }
  }
}
```

### Pattern 6: Custom formatters
```javascript
// model/formatter.js
sap.ui.define([], function () {
  "use strict";
  return {
    statusText: function (sStatus) {
      const oBundle = this.getOwnerComponent().getModel("i18n").getResourceBundle();
      switch (sStatus) {
        case "A": return oBundle.getText("statusActive");
        case "I": return oBundle.getText("statusInactive");
        default:  return sStatus;
      }
    },
    currencyValue: function (sValue) {
      return sValue ? parseFloat(sValue).toFixed(2) : "";
    }
  };
});
```

Use in XML:
```xml
<Text text="{path: 'Status', formatter: '.formatter.statusText'}" />
```

## Error Catalog

| Error | Cause | Fix |
|-------|-------|-----|
| `Cannot read property 'getText' of undefined` | i18n model not loaded when controller reads it | Read i18n inside `onInit` AFTER `this.getView().getModel("i18n").getResourceBundle()` is available, not at module scope |
| `The given binding path "/X" is invalid` | Path doesn't exist in model or model name is wrong | Use debug tools (Ctrl+Alt+Shift+P) to inspect bindings; check model name prefix (`i18n>`, `device>`) |
| `404 on /sap/opu/odata/...` | Service not activated or wrong path | In SEGW: activate service in `/IWFND/MAINT_SERVICE`; in RAP: check service binding `Publish` |
| `No class sap.m.Xyz` | Typo in control name or library not loaded | Check spelling, add the library to `sap.ui5.dependencies.libs` in manifest.json |
| `Cannot read properties of null (reading 'getBindingContext')` | Control not yet rendered when handler fires | Use `onAfterRendering` or `attachEventOnce` instead of `onInit` |
| `CSRF token validation failed` | Missing X-CSRF-Token on write requests | ODataModel handles this automatically; if using custom fetch, first send `GET` with `X-CSRF-Token: Fetch`, reuse token for POST/PUT/DELETE |
| `sap.ui.model.odata.v4.ODataListBinding: Path does not have a type` | `autoExpandSelect: true` with a path the service doesn't expose | Set `autoExpandSelect: false` OR make sure every bound property is in the service metadata |
| `UI5 app works locally but 404 on BTP` | `destinations` not configured in xs-app.json | Add a route pointing to the destination; verify destination exists in BTP cockpit |

## Performance Tips

1. **`autoExpandSelect: true`** (OData v4) — UI5 automatically adds `$select` and `$expand` based on bindings, reducing payload size by 60–80%.
2. **`growing="true"` with `growingThreshold`** — never load thousands of rows; let the user scroll to fetch more.
3. **Preload components** — set `"preload": true` on critical models in manifest for parallel loading.
4. **Use `sap.ui.table.Table` for 1000+ rows** — it virtualizes rows, unlike `sap.m.Table`.
5. **Avoid `forceUpdate()`** — prefer binding refresh over full re-render.
6. **Lazy-load fragments** — load dialogs/popovers on first open, not in `onInit`.
7. **`async: true` in Component** — enable async routing and view loading.
8. **Use `sap-ui-compatVersion=edge`** — removes legacy code paths.
9. **Minify + preload in build** — `ui5 build --clean-dest --all` produces `Component-preload.js` (single-file bundle).
10. **Avoid deep `$expand`** — prefer separate batch requests; deeply nested expands kill response time.

## Gotchas

- **`this` binding in async callbacks** — use arrow functions or `.bind(this)`; regular function expressions lose `this`.
- **OData v2 vs v4 path syntax** — v2: `/Products('HT-1001')`; v4: `/Products(ID='HT-1001')`. They are NOT interchangeable.
- **Two-way binding requires `change` events** — without them, the model is updated but the server is not.
- **`sap.ui.getCore().byId()` is deprecated** — use `this.byId()` inside controllers or view's `byId()`.
- **Fragments share the controller of the view that loaded them** — event handlers refer to the view controller, not a separate one.
- **Duplicate IDs across fragments** — when a fragment is loaded multiple times, prefix IDs with `this.createId()` or use `addDependent()`.
- **`manifest.json` changes need a full app reload** — hot-reload doesn't pick them up.
- **`sap.m.Table` vs `sap.ui.table.Table`** — the first is responsive (mobile-first), the second is desktop-only. Pick based on target devices.

## Fiori Elements (when to use it)

**Use Fiori Elements when:**
- The UI is mostly CRUD over a well-modeled entity
- You want consistent Fiori look without custom code
- You can annotate the backend (CAP/CDS) with UI.* annotations
- The template (LROP/OVP/ALP) matches the use case

**Avoid Fiori Elements when:**
- The UI needs heavy customization (custom visualizations, wizards)
- The data model is flat or non-standard
- You need pixel-perfect design control

**Templates:**
- **LROP** (List Report Object Page): filter → table → detail — the most common pattern
- **OVP** (Overview Page): card-based dashboard
- **ALP** (Analytical List Page): chart + table analytics
- **Worklist**: focused task lists

**Custom extensions:**
- Extension points: `@sap/ux-specification` defines where you can inject custom fragments/controllers
- Flexible programming model: `sap.fe.core.controllerextensions.*` for lifecycle hooks

## References

- `references/bindings-cheatsheet.md` — Complete binding syntax reference
- `references/fiori-elements-annotations.md` — UI.* annotation catalog for LROP/OVP/ALP
- `references/controls-catalog.md` — When to use which UI5 control
- `templates/controller-template.js` — Copy-paste controller skeleton
- `templates/xml-view-template.xml` — Copy-paste XML view skeleton
- `templates/manifest-template.json` — Copy-paste manifest.json

## MCP Server Integration

For live UI5 development assistance, pair this skill with:
- `@ui5/mcp-server` — UI5 control info, API lookup, sample code
- `@sap-ux/fiori-mcp-server` — Fiori Tools operations (generate app, build, deploy)
- `@sap/mdk-mcp-server` — MDK for mobile-first scenarios

Install via `mcp-configs/fullstack-btp.json`.
