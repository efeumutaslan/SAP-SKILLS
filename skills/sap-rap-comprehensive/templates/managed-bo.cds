// ============================================================
// RAP Managed Business Object — Complete Template
// Replace {{PLACEHOLDER}} values with your names
// ============================================================

// --- 1. Database Table ---
// Create via ADT: New > Dictionary > Database Table
// @EndUserText.label : '{{Entity Description}}'
// define table {{ztab_entity}} {
//   key client         : abap.clnt not null;
//   key {{entity}}_uuid : sysuuid_x16 not null;
//   {{entity}}_id       : abap.numc(8);
//   description         : abap.char(256);
//   status              : abap.char(1);
//   @Semantics.amount.currencyCode : '{{ztab_entity}}.currency_code'
//   total_amount        : abap.curr(15,2);
//   currency_code       : abap.cuky;
//   created_by          : syuname;
//   created_at          : timestampl;
//   last_changed_by     : syuname;
//   last_changed_at     : timestampl;
//   local_last_changed_at : timestampl;
// }

// --- 2. CDS View Entity (Interface Layer) ---
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '{{Entity Description}}'
define root view entity {{ZI_Entity}}
  as select from {{ztab_entity}}
{
  key {{entity}}_uuid            as {{Entity}}UUID,
      {{entity}}_id              as {{Entity}}ID,
      description                as Description,
      status                     as Status,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_amount               as TotalAmount,
      currency_code              as CurrencyCode,
      @Semantics.user.createdBy: true
      created_by                 as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                 as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by            as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at            as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at      as LocalLastChangedAt
}

// --- 3. CDS Projection View (Consumption Layer) ---
// @AccessControl.authorizationCheck: #CHECK
// @EndUserText.label: '{{Entity Description}} - Projection'
// @Metadata.allowExtensions: true
// define root view entity {{ZC_Entity}}
//   provider contract transactional_query
//   as projection on {{ZI_Entity}}
// {
//   key {{Entity}}UUID,
//       {{Entity}}ID,
//       Description,
//       Status,
//       TotalAmount,
//       CurrencyCode,
//       CreatedBy,
//       CreatedAt,
//       LastChangedBy,
//       LastChangedAt,
//       LocalLastChangedAt
// }

// --- 4. Behavior Definition ---
// managed implementation in class {{zbp_i_entity}} unique;
// strict ( 2 );
// with draft;
//
// define behavior for {{ZI_Entity}} alias {{Entity}}
// persistent table {{ztab_entity}}
// draft table {{zdraft_entity}}
// etag master LocalLastChangedAt
// lock master total etag LastChangedAt
// authorization master ( global, instance )
// {
//   field ( readonly ) {{Entity}}UUID;
//   field ( numbering : managed ) {{Entity}}UUID;
//   field ( mandatory ) Description;
//
//   create; update; delete;
//
//   determination SetDefaults on modify { create; }
//   validation ValidateDescription on save { field Description; }
//
//   draft action Resume;
//   draft action Edit;
//   draft action Activate optimized;
//   draft action Discard;
//   draft determine action Prepare;
//
//   mapping for {{ztab_entity}} corresponding;
// }

// --- 5. Service Definition ---
// define service {{ZSD_Entity}} {
//   expose {{ZC_Entity}} as {{Entity}};
// }

// --- 6. Service Binding ---
// Create via ADT: New > Service Binding
// Binding Type: OData V4 - UI
// Service Definition: {{ZSD_Entity}}
