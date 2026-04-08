// Controller template for a freestyle SAPUI5 app.
// Replace {{APP_NAMESPACE}} and {{VIEW_NAME}} with your values.
sap.ui.define([
  "sap/ui/core/mvc/Controller",
  "sap/ui/model/json/JSONModel",
  "sap/ui/model/Filter",
  "sap/ui/model/FilterOperator",
  "sap/ui/model/Sorter",
  "sap/m/MessageToast",
  "sap/m/MessageBox",
  "{{APP_NAMESPACE}}/model/formatter"
], function (Controller, JSONModel, Filter, FilterOperator, Sorter, MessageToast, MessageBox, formatter) {
  "use strict";

  return Controller.extend("{{APP_NAMESPACE}}.controller.{{VIEW_NAME}}", {

    formatter: formatter,

    // ---------- lifecycle ----------

    onInit: function () {
      // View state (busy flag, UI-only values)
      const oViewModel = new JSONModel({
        busy: false,
        delay: 0,
        selectedCount: 0
      });
      this.getView().setModel(oViewModel, "viewModel");

      // Route handler (runs each time the user navigates to this view)
      this.getOwnerComponent()
        .getRouter()
        .getRoute("{{ROUTE_NAME}}")
        .attachPatternMatched(this._onRouteMatched, this);
    },

    onExit: function () {
      // Clean up fragments, observers, etc.
      if (this._oDialog) {
        this._oDialog.destroy();
      }
    },

    // ---------- route handler ----------

    _onRouteMatched: function (oEvent) {
      const oArgs = oEvent.getParameter("arguments");
      // Use oArgs.paramName to read route params
      this.getView().bindElement({
        path: "/{{ENTITY_SET}}('" + oArgs.id + "')",
        parameters: { $expand: "{{EXPAND_PATH}}" },
        events: {
          dataRequested: () => this._setBusy(true),
          dataReceived:  () => this._setBusy(false)
        }
      });
    },

    // ---------- event handlers ----------

    onRefresh: function () {
      const oBinding = this.byId("{{LIST_ID}}").getBinding("items");
      oBinding.refresh();
      MessageToast.show(this._t("msgRefreshed"));
    },

    onSearch: function (oEvent) {
      const sQuery = oEvent.getParameter("query") || "";
      const aFilters = sQuery
        ? [new Filter("Name", FilterOperator.Contains, sQuery)]
        : [];
      this.byId("{{LIST_ID}}").getBinding("items").filter(aFilters);
    },

    onSort: function (oEvent) {
      const bDescending = oEvent.getParameter("selected");
      const oSorter = new Sorter("Name", bDescending);
      this.byId("{{LIST_ID}}").getBinding("items").sort([oSorter]);
    },

    onItemPress: function (oEvent) {
      const oContext = oEvent.getSource().getBindingContext();
      const oData = oContext.getObject();
      this.getOwnerComponent().getRouter().navTo("{{DETAIL_ROUTE}}", {
        id: oData.ID
      });
    },

    onSave: async function () {
      const oModel = this.getView().getModel();
      try {
        this._setBusy(true);
        await oModel.submitBatch(oModel.getUpdateGroupId());
        MessageToast.show(this._t("msgSaved"));
      } catch (oError) {
        MessageBox.error(this._t("msgSaveFailed") + "\n" + oError.message);
      } finally {
        this._setBusy(false);
      }
    },

    onDelete: function () {
      MessageBox.confirm(this._t("msgDeleteConfirm"), {
        onClose: (sAction) => {
          if (sAction === MessageBox.Action.OK) {
            const oContext = this.getView().getBindingContext();
            oContext.delete("$auto").then(() => {
              MessageToast.show(this._t("msgDeleted"));
              this.getOwnerComponent().getRouter().navTo("{{LIST_ROUTE}}");
            });
          }
        }
      });
    },

    // ---------- fragment / dialog ----------

    onOpenAddDialog: async function () {
      if (!this._oDialog) {
        this._oDialog = await this.loadFragment({ name: "{{APP_NAMESPACE}}.view.AddDialog" });
      }
      this._oDialog.open();
    },

    onDialogOk: function () {
      // Read values, submit, then close
      this._oDialog.close();
    },

    onDialogCancel: function () {
      this._oDialog.close();
    },

    // ---------- helpers ----------

    _setBusy: function (bBusy) {
      this.getView().getModel("viewModel").setProperty("/busy", bBusy);
    },

    _t: function (sKey, aArgs) {
      return this.getView().getModel("i18n").getResourceBundle().getText(sKey, aArgs);
    }

  });
});
