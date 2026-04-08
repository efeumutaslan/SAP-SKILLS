# Fiori Elements UI Annotations Reference

CDS/OData annotations that drive Fiori Elements templates. Write these in your backend; the UI renders automatically.

## Table of Contents

- [HeaderInfo](#headerinfo)
- [LineItem (Table columns)](#lineitem-table-columns)
- [SelectionFields (Filter Bar)](#selectionfields-filter-bar)
- [FieldGroup (Form Sections)](#fieldgroup-form-sections)
- [Facets (Object Page Layout)](#facets-object-page-layout)
- [Identification (Header Actions)](#identification-header-actions)
- [DataPoint (KPI/Progress)](#datapoint-kpiprogress)
- [Chart](#chart)
- [PresentationVariant](#presentationvariant)
- [SelectionVariant](#selectionvariant)
- [Common Data Annotations](#common-data-annotations)
- [Criticality (Semantic Coloring)](#criticality-semantic-coloring)
- [ValueList (Value Helps)](#valuelist-value-helps)
- [Capabilities](#capabilities)
- [Template Anatomy](#template-anatomy)

## HeaderInfo

Defines the header of the object page.

```cds
annotate Products with @(
  UI.HeaderInfo: {
    TypeName: 'Product',
    TypeNamePlural: 'Products',
    Title:       { Value: Name },
    Description: { Value: Category },
    ImageUrl:    ImageUrl
  }
);
```

## LineItem (Table columns)

Columns shown in the list report / object page tables.

```cds
annotate Products with @(
  UI.LineItem: [
    { Value: ID,        Label: 'Product ID' },
    { Value: Name,      Label: 'Name' },
    { Value: Category },
    { Value: Price,     Label: 'Price' },
    { Value: Stock,     Criticality: StockCriticality },
    {
      $Type: 'UI.DataFieldForAction',
      Action: 'MyService.EntityContainer/orderMore',
      Label: 'Order More'
    }
  ]
);
```

**Column types:**
- `UI.DataField` (default) — Bound property
- `UI.DataFieldForAction` — Button that calls an action
- `UI.DataFieldForIntentBasedNavigation` — Navigate to another app
- `UI.DataFieldWithUrl` — Link
- `UI.DataFieldWithNavigationPath` — Navigation property link

## SelectionFields (Filter Bar)

Properties shown in the filter bar of list reports.

```cds
annotate Products with @(
  UI.SelectionFields: [
    Category,
    Price,
    Stock,
    Supplier_ID
  ]
);
```

## FieldGroup (Form Sections)

Groups of fields for forms (object page details).

```cds
annotate Products with @(
  UI.FieldGroup #GeneralInfo: {
    $Type: 'UI.FieldGroupType',
    Label: 'General Information',
    Data: [
      { Value: ID },
      { Value: Name },
      { Value: Description },
      { Value: Category }
    ]
  },
  UI.FieldGroup #Pricing: {
    Data: [
      { Value: Price },
      { Value: CurrencyCode },
      { Value: TaxRate }
    ]
  }
);
```

## Facets (Object Page Layout)

Controls the sections of the object page, referencing FieldGroups and tables.

```cds
annotate Products with @(
  UI.Facets: [
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'General',
      Target: '@UI.FieldGroup#GeneralInfo'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Pricing',
      Target: '@UI.FieldGroup#Pricing'
    },
    {
      $Type: 'UI.ReferenceFacet',
      Label: 'Reviews',
      Target: 'reviews/@UI.LineItem'      // navigation to child entity
    },
    {
      $Type: 'UI.CollectionFacet',
      Label: 'Supply Chain',
      Facets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#Supplier' },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.FieldGroup#Warehouse' }
      ]
    }
  ]
);
```

## Identification (Header Actions)

Primary actions shown in the object page header.

```cds
annotate Products with @(
  UI.Identification: [
    { Value: Name },
    {
      $Type: 'UI.DataFieldForAction',
      Action: 'MyService.EntityContainer/approve',
      Label: 'Approve'
    }
  ]
);
```

## DataPoint (KPI/Progress)

Numeric values with targets and visualization.

```cds
annotate Products with @(
  UI.DataPoint #stock: {
    Value: Stock,
    Title: 'Stock Level',
    TargetValue: 1000,
    Criticality: StockCriticality,
    Visualization: #Rating  // or #Progress, #BulletChart
  }
);
```

## Chart

```cds
annotate Sales with @(
  UI.Chart: {
    ChartType: #Column,
    Title: 'Sales by Region',
    Dimensions: [ Region ],
    Measures: [ TotalRevenue ],
    DimensionAttributes: [
      { Dimension: Region, Role: #Category }
    ],
    MeasureAttributes: [
      { Measure: TotalRevenue, Role: #Axis1 }
    ]
  }
);
```

Chart types: `#Column`, `#Line`, `#Pie`, `#Donut`, `#Bar`, `#Area`, `#Bubble`, `#Scatter`, `#HeatMap`

## PresentationVariant

Combines table, chart, filter defaults, and sort order.

```cds
annotate Products with @(
  UI.PresentationVariant: {
    Visualizations: [
      '@UI.LineItem',
      '@UI.Chart'
    ],
    SortOrder: [
      { Property: Price, Descending: true }
    ],
    GroupBy: [ Category ],
    MaxItems: 100
  }
);
```

## SelectionVariant

Pre-defined filter combinations.

```cds
annotate Products with @(
  UI.SelectionVariant #cheap: {
    Text: 'Cheap Products',
    SelectOptions: [
      {
        PropertyName: Price,
        Ranges: [{ Sign: #I, Option: #LE, Low: 50 }]
      }
    ]
  }
);
```

## Common Data Annotations

Influence how fields are rendered:

```cds
annotate Products with {
  @Common.Label: 'Product Name'
  @Common.Text: Name
  @Common.Text.@UI.TextArrangement: #TextOnly   // show text, not ID
  ID;

  @Measures.ISOCurrency: CurrencyCode
  Price;

  @Measures.Unit: UnitOfMeasure
  Quantity;

  @Common.IsUpperCase: true
  Code;
};
```

**Text arrangements:**
- `#TextFirst` — "Product Name (HT-1001)"
- `#TextLast` — "HT-1001 (Product Name)"
- `#TextOnly` — "Product Name"
- `#TextSeparate` — Two columns

## Criticality (Semantic Coloring)

Values 0-5 map to colors:
- 0 = Neutral (grey)
- 1 = Negative (red)
- 2 = Critical (orange/yellow)
- 3 = Positive (green)
- 4 = Information (blue)
- 5 = Positive (dark green)

```cds
annotate Products with @(
  UI.LineItem: [
    { Value: Stock, Criticality: StockCriticality }
  ]
);
```

Computed criticality in CDS:
```cds
entity Products : cuid {
  stock: Integer;
  stockCriticality: Integer = case
    when stock > 100 then 3
    when stock > 10  then 2
    else                  1
  end;
}
```

## ValueList (Value Helps)

Auto-generated F4 help for input fields.

```cds
annotate Products with {
  Category @(
    Common.ValueList: {
      CollectionPath: 'Categories',
      Parameters: [
        { $Type: 'Common.ValueListParameterInOut', LocalDataProperty: Category, ValueListProperty: 'ID' },
        { $Type: 'Common.ValueListParameterDisplayOnly', ValueListProperty: 'Description' }
      ]
    }
  );
};
```

## Capabilities

Control what the client can do (filter, sort, search, etc.):

```cds
annotate ProductsService.Products with @(
  Capabilities.FilterRestrictions: {
    NonFilterableProperties: [ Description ]
  },
  Capabilities.SortRestrictions: {
    NonSortableProperties: [ Description ]
  },
  Capabilities.SearchRestrictions.Searchable: true,
  Capabilities.UpdateRestrictions.Updatable: true,
  Capabilities.DeleteRestrictions.Deletable: true,
  Capabilities.InsertRestrictions.Insertable: true
);
```

## Template Anatomy

### List Report Object Page (LROP)
- Uses: `UI.LineItem`, `UI.SelectionFields`, `UI.HeaderInfo`, `UI.Facets`, `UI.FieldGroup`
- Required for drilldown: object page needs `HeaderInfo` + `Facets`

### Overview Page (OVP)
- Uses: `UI.Chart`, `UI.DataPoint`, `UI.PresentationVariant`, `UI.SelectionVariant`
- Each card is driven by a `UI.PresentationVariant`

### Analytical List Page (ALP)
- Uses: `UI.Chart`, `UI.LineItem`, `UI.SelectionFields`
- Combines filter → chart + table view

### Worklist
- Uses: `UI.LineItem`, `UI.SelectionFields`
- Similar to LROP but without hierarchical object page

## Gotchas

- **Annotations must be in the service layer**, not in core CDS — use `annotate` inside the `service` definition or in a `.cds` file imported by it.
- **Navigation properties need `@Common.ValueList`** for F4 help to work automatically.
- **`@UI.Facets` is mandatory for object page** — without it, drilldown shows an empty page.
- **Action labels** must be defined in `@Common.Label` on the action definition, not on the annotation.
- **`$Type` is optional for common cases** — Fiori Elements infers `UI.DataField` by default for `LineItem` entries.
- **Text arrangement without `@Common.Text` is ignored** — always pair `TextArrangement` with a `Text` annotation.
