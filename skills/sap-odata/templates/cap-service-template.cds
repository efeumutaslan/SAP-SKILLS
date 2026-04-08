// CAP OData v4 service template
// Replace {{SERVICE_NAME}}, {{ENTITY_NAME}}, and field names with your values.

using { my.db as db } from '../db/schema';

// --- Main service ---------------------------------------------------------
@path: '/{{SERVICE_PATH}}'                  // e.g. '/products'
@(requires: 'authenticated-user')           // XSUAA auth
service {{SERVICE_NAME}} {

  // Plain entity projection
  entity {{ENTITY_NAME}} as projection on db.{{ENTITY_NAME}} {
    *,
    // Virtual / calculated field
    criticality: Integer @Core.Computed
  };

  // Entity with annotations (Fiori Elements ready)
  @(restrict: [
    { grant: 'READ',              to: 'Viewer' },
    { grant: ['CREATE','UPDATE'], to: 'Editor' },
    { grant: '*',                 to: 'Admin'  }
  ])
  entity {{ENTITY_NAME}}Admin as projection on db.{{ENTITY_NAME}};

  // Action (POST, side-effects)
  @Core.Description: 'Approve an entity'
  action approve(ID: String) returns {{ENTITY_NAME}};

  // Bound action
  extend entity {{ENTITY_NAME}} with actions {
    action activate() returns {{ENTITY_NAME}};
    action deactivate() returns {{ENTITY_NAME}};
  };

  // Function (GET, no side-effects)
  @Core.Description: 'Get entities above a price threshold'
  function aboveThreshold(threshold: Decimal(10,2)) returns array of {{ENTITY_NAME}};
}

// --- UI annotations (Fiori Elements LROP) ---------------------------------
annotate {{SERVICE_NAME}}.{{ENTITY_NAME}} with @(

  UI.HeaderInfo: {
    TypeName:       '{{ENTITY_LABEL}}',
    TypeNamePlural: '{{ENTITY_LABEL_PLURAL}}',
    Title:          { Value: name },
    Description:    { Value: category }
  },

  UI.LineItem: [
    { Value: ID,       Label: 'ID' },
    { Value: name,     Label: 'Name' },
    { Value: category, Label: 'Category' },
    { Value: price,    Label: 'Price' },
    { Value: stock,    Criticality: criticality }
  ],

  UI.SelectionFields: [ category, price, stock ],

  UI.FieldGroup #General: {
    Data: [
      { Value: ID },
      { Value: name },
      { Value: category },
      { Value: description }
    ]
  },

  UI.FieldGroup #Pricing: {
    Data: [
      { Value: price },
      { Value: currencyCode },
      { Value: stock }
    ]
  },

  UI.Facets: [
    { $Type: 'UI.ReferenceFacet', Label: 'General', Target: '@UI.FieldGroup#General' },
    { $Type: 'UI.ReferenceFacet', Label: 'Pricing', Target: '@UI.FieldGroup#Pricing' }
  ]
);

// --- Common annotations ---------------------------------------------------
annotate {{SERVICE_NAME}}.{{ENTITY_NAME}} with {
  @Common.Label: 'Product Name'
  name;

  @Measures.ISOCurrency: currencyCode
  price;

  @Common.ValueList: {
    CollectionPath: 'Categories',
    Parameters: [
      { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: category, ValueListProperty: 'code' }
    ]
  }
  category;
};

// --- Service implementation hook (srv/{{SERVICE_NAME}}.js) ---------------
// module.exports = cds.service.impl(async function () {
//   const { {{ENTITY_NAME}} } = this.entities;
//
//   this.on('approve', async req => {
//     const id = req.data.ID;
//     await UPDATE({{ENTITY_NAME}}).set({ status: 'approved' }).where({ ID: id });
//     return SELECT.one.from({{ENTITY_NAME}}).where({ ID: id });
//   });
//
//   this.before('CREATE', {{ENTITY_NAME}}, req => {
//     if (!req.data.ID) req.data.ID = cds.utils.uuid();
//   });
// });
