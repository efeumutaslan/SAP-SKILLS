// CDS View Extension Templates
// Replace {{PLACEHOLDER}} values with your actual names
//
// Prerequisite: Target CDS view must have annotation
// @AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]

// ============================================================
// Template 1: Add custom field from extension include
// ============================================================
extend view entity {{I_TARGET_CDS_VIEW}}
  with {
    {{source_alias}}.{{YY1_CustomField}} as {{CustomFieldAlias}}
  }

// ============================================================
// Template 2: Add association to custom CDS view
// ============================================================
extend view entity {{I_TARGET_CDS_VIEW}}
  with association [0..*] to {{ZI_CUSTOM_CDS_VIEW}} as {{_CustomAlias}}
    on $projection.{{JoinField}} = {{_CustomAlias}}.{{JoinField}}
  {
    {{_CustomAlias}}
  }

// ============================================================
// Template 3: Add calculated field via extension
// ============================================================
extend view entity {{I_TARGET_CDS_VIEW}}
  with {
    case {{source_alias}}.{{StatusField}}
      when 'A' then 'Active'
      when 'I' then 'Inactive'
      else 'Unknown'
    end as {{StatusText}}
  }
