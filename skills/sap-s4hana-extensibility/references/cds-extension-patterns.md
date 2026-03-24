# CDS View Extension Patterns

## Prerequisites

For a CDS view to be extensible, it must carry one of these annotations:

```cds
@AbapCatalog.viewEnhancementCategory: [#NONE]              -- Not extensible
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]    -- Fields can be added
@AbapCatalog.viewEnhancementCategory: [#GROUP_BY]           -- GROUP BY extensions
@AbapCatalog.viewEnhancementCategory: [#UNION]              -- UNION extensions
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST, #GROUP_BY]  -- Combined
```

Only CDS views released with **C0 contract** (Extensibility) can be extended in ABAP Cloud.

## Pattern 1: Add Custom Field from Extension Include

When a custom field has been added to the underlying database table via Custom Fields app:

```cds
extend view entity I_PurchaseOrderItemAPI01
  with
{
  pur_doc_item.YY1_CostCenter as CostCenterCustom
}
```

**How it works:**
- `pur_doc_item` is the alias of the data source in the original CDS view
- `YY1_CostCenter` is the field added via Custom Fields (stored in extension include)
- The field becomes available in the extended CDS view's result set

## Pattern 2: Add Association to Custom Entity

```cds
extend view entity I_SalesOrder
  with association [0..*] to ZI_SalesOrderCustomData as _CustomData
    on $projection.SalesOrder = _CustomData.SalesOrder
{
  _CustomData
}
```

**Use cases:**
- Link standard SAP entities to custom Z-tables
- Add custom master data references
- Cross-reference with external system data

## Pattern 3: Add Calculated/Derived Field

```cds
extend view entity I_SalesOrderItem
  with
{
  case sls_doc_item.OverallSDProcessStatus
    when 'A' then 'Not Yet Processed'
    when 'B' then 'Partially Processed'
    when 'C' then 'Completely Processed'
    else 'Unknown'
  end as ProcessStatusText
}
```

## Pattern 4: Add Annotations to Extended Fields

```cds
extend view entity I_PurchaseOrder
  with
{
  @EndUserText.label: 'Custom Project Reference'
  @UI.lineItem: [{ position: 90 }]
  @UI.selectionField: [{ position: 40 }]
  pur_doc.YY1_ProjectRef as ProjectReference
}
```

## Pattern 5: Extend with Multiple Associations

```cds
extend view entity I_BusinessPartner
  with association [0..1] to ZI_BPCreditRating as _CreditRating
    on $projection.BusinessPartner = _CreditRating.BusinessPartner
  association [0..*] to ZI_BPCustomTags as _CustomTags
    on $projection.BusinessPartner = _CustomTags.BusinessPartner
{
  _CreditRating,
  _CustomTags,
  _CreditRating.RatingScore as CreditScore
}
```

## Pattern 6: Extend Projection/Consumption View

```cds
@Metadata.layer: #CUSTOMER
extend view entity C_PurchaseOrderTP
  with
{
  @UI.lineItem: [{ position: 100, label: 'Custom Cost Center' }]
  @UI.identification: [{ position: 100, label: 'Custom Cost Center' }]
  _Item._CustomData.CostCenter as CustomCostCenter
}
```

**Note:** Projection extensions follow the same syntax but often add UI annotations
for Fiori Elements display.

## Pattern 7: Metadata Extension (UI Annotations Only)

When you only need to change the UI layout without adding new fields:

```cds
@Metadata.layer: #CUSTOMER
annotate entity C_PurchaseOrderTP with
{
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  PurchaseOrder;

  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  PurchaseOrderType;

  @UI.hidden: true
  InternalComment;
}
```

**Metadata layers (priority order):**
1. `#CORE` — SAP standard (lowest priority)
2. `#PARTNER` — Partner extensions
3. `#INDUSTRY` — Industry solutions
4. `#CUSTOMER` — Customer extensions (highest priority, overrides all)

## Old Syntax vs New Syntax

### Old (deprecated): `EXTEND VIEW`
```cds
@AbapCatalog.sqlViewAppendName: 'ZX_SALESORDER'
extend view I_SalesOrder with ZX_SalesOrder {
  pur_doc.YY1_Custom as CustomField
}
```

### New (current): `EXTEND VIEW ENTITY`
```cds
extend view entity I_SalesOrder
  with
{
  pur_doc.YY1_Custom as CustomField
}
```

**Always use the new `EXTEND VIEW ENTITY` syntax.** The old syntax is deprecated
and will not be enhanced.

## Finding Extensible CDS Views

### Method 1: ADT Released Objects
```
Project Explorer → Released Objects → filter: DDLS (CDS View)
→ Check API State: "Use in Cloud Development" + C0 contract
```

### Method 2: api.sap.com
```
api.sap.com → S/4HANA Cloud → CDS Views → filter: "Extensibility Contract C0"
```

### Method 3: ADT Properties
```
Right-click CDS view → Properties → API State
Look for: Release Contract = C0 (Extensibility)
```

### Method 4: ATC Check
```
Run ATC with ABAP_CLOUD_READINESS variant
If your extension compiles → the target CDS view is extensible
If ATC flags it → the target is not released for extension
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "View entity does not allow extensions" | No `@AbapCatalog.viewEnhancementCategory` annotation | CDS view is not extensible; find alternative |
| "Data source alias not found" | Wrong alias used for source table | Check original CDS view for correct data source aliases |
| "Field already exists" | Extension field name conflicts with existing field | Use unique Z/YY1-prefixed alias names |
| "Association target not accessible" | Target CDS view not released | Create your own I_ view and associate to that |
| "Type mismatch in ON condition" | Join field types don't match | Cast fields to matching types in ON condition |
| Activation warning "Append view" | Old-syntax EXTEND VIEW used | Migrate to `EXTEND VIEW ENTITY` syntax |

## Best Practices

1. **Unique naming**: Always use `YY1_` or `Z` prefix for extension aliases
2. **Minimal extensions**: Only add fields you actually need
3. **Document purpose**: Add `@EndUserText.label` to every extended field
4. **Test impact**: After extending, verify Fiori apps still work correctly
5. **UI annotations**: Add `@UI` annotations in metadata extensions, not in CDS extensions
6. **Performance**: Avoid adding complex calculations in extensions (use determination/BAdI instead)
7. **Compatibility**: Run ATC checks after creating extensions
