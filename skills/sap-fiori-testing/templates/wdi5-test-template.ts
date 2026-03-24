// wdi5 E2E Test Template for SAP Fiori / UI5 Applications
// Replace: {{APP_ID}}, {{ENTITY}}, {{VIEW_NAME}}
// Prerequisites: npm install --save-dev @wdio/cli wdio-ui5-service

import { wdi5Selector } from "wdio-ui5-service";

describe("{{APP_ID}} — {{VIEW_NAME}}", () => {
  // ============================================================
  // Setup
  // ============================================================
  before(async () => {
    await browser.url("#/{{ENTITY}}");
    // Wait for UI5 to fully load
    await browser.asControl({
      selector: {
        controlType: "sap.m.Page",
        viewName: "{{APP_ID}}.view.{{VIEW_NAME}}",
      },
    });
  });

  // ============================================================
  // List Page Tests
  // ============================================================
  describe("List Report", () => {
    it("should display table with records", async () => {
      const table = await browser.asControl({
        selector: {
          controlType: "sap.m.Table",
          viewName: "{{APP_ID}}.view.{{VIEW_NAME}}",
        },
      });
      const items = await table.getItems();
      expect(items.length).toBeGreaterThan(0);
    });

    it("should filter by search field", async () => {
      const searchField = await browser.asControl({
        selector: {
          controlType: "sap.m.SearchField",
          viewName: "{{APP_ID}}.view.{{VIEW_NAME}}",
        },
      });
      await searchField.setValue("TEST");
      await searchField.fireSearch();

      // Verify filtered results
      const table = await browser.asControl({
        selector: {
          controlType: "sap.m.Table",
          viewName: "{{APP_ID}}.view.{{VIEW_NAME}}",
        },
      });
      const items = await table.getItems();
      for (const item of items) {
        const cells = await item.getCells();
        const text = await cells[0].getText();
        expect(text.toUpperCase()).toContain("TEST");
      }
    });

    it("should navigate to detail on item press", async () => {
      const table = await browser.asControl({
        selector: {
          controlType: "sap.m.Table",
          viewName: "{{APP_ID}}.view.{{VIEW_NAME}}",
        },
      });
      const items = await table.getItems();
      await items[0].firePress();

      // Verify navigation
      const detailPage = await browser.asControl({
        selector: {
          controlType: "sap.uxap.ObjectPageLayout",
          viewName: "{{APP_ID}}.view.Detail",
        },
      });
      expect(detailPage).toBeDefined();
    });
  });

  // ============================================================
  // Object Page Tests
  // ============================================================
  describe("Object Page", () => {
    it("should display header with correct title", async () => {
      const header = await browser.asControl({
        selector: {
          controlType: "sap.uxap.ObjectPageHeader",
          viewName: "{{APP_ID}}.view.Detail",
        },
      });
      const title = await header.getObjectTitle();
      expect(title).not.toBe("");
    });

    it("should edit and save", async () => {
      // Press Edit
      const editBtn = await browser.asControl({
        selector: {
          controlType: "sap.m.Button",
          viewName: "{{APP_ID}}.view.Detail",
          properties: { text: "Edit" },
        },
      });
      await editBtn.firePress();

      // Modify a field
      const input = await browser.asControl({
        selector: {
          controlType: "sap.m.Input",
          viewName: "{{APP_ID}}.view.Detail",
          bindingPath: { propertyPath: "Description" },
        },
      });
      await input.setValue("Updated via wdi5 test");

      // Save
      const saveBtn = await browser.asControl({
        selector: {
          controlType: "sap.m.Button",
          viewName: "{{APP_ID}}.view.Detail",
          properties: { text: "Save" },
        },
      });
      await saveBtn.firePress();

      // Verify message toast
      // wdi5 doesn't directly capture MessageToast — check state instead
      const displayInput = await browser.asControl({
        selector: {
          controlType: "sap.m.Text",
          viewName: "{{APP_ID}}.view.Detail",
          bindingPath: { propertyPath: "Description" },
        },
      });
      const text = await displayInput.getText();
      expect(text).toBe("Updated via wdi5 test");
    });
  });

  // ============================================================
  // Accessibility Tests
  // ============================================================
  describe("Accessibility", () => {
    it("should have no critical axe violations", async () => {
      // Requires @axe-core/webdriverio
      const { AxeBuilder } = require("@axe-core/webdriverio");
      const results = await new AxeBuilder({ client: browser })
        .withTags(["wcag2a", "wcag2aa"])
        .analyze();
      expect(results.violations.filter((v: any) => v.impact === "critical")).toHaveLength(0);
    });
  });
});
