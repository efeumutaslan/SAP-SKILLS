@EndUserText.label: '{{SERVICE_LABEL}}'
define service {{SERVICE_NAME}} {
  expose {{ROOT_PROJECTION}}  as {{ENTITY_SET_NAME}};
  expose {{CHILD_PROJECTION}} as {{CHILD_SET_NAME}};

  // Value help entities (if not auto-exposed via associations)
  expose {{VH_PROJECTION}}    as {{VH_SET_NAME}};
}

// -----------------------------------------------------------------------
// In ADT, create a Service Binding ({{SERVICE_BINDING}}) that references
// this Service Definition with:
//
//   Binding Type:     OData V4 - UI
//   Service Definition: {{SERVICE_NAME}}
//
// Published URL pattern:
//   /sap/opu/odata4/sap/{{SERVICE_BINDING}}/srvd_a2x/sap/{{SERVICE_NAME}}/0001/
// -----------------------------------------------------------------------
