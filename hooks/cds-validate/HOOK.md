---
name: cds-validate
description: CDS view validation hook. Triggers on .cds/.asddls file save. Checks annotation completeness, naming conventions, and common CDS issues.
trigger: file-save
file-patterns: ["*.cds", "*.asddls"]
---

# CDS Validate Hook

Automatically validates CDS view definitions when `.cds` or `.asddls` files are saved.

## Rules

### Required Annotations
| Annotation | When Required | Default |
|------------|---------------|---------|
| `@AccessControl.authorizationCheck` | Always on root views | `#CHECK` |
| `@EndUserText.label` | Always | Entity name as label |
| `@ObjectModel.usageType.serviceQuality` | Service-exposed views | `#A` (best) |
| `@ObjectModel.usageType.dataClass` | All views | `#MIXED` |
| `@ObjectModel.usageType.sizeCategory` | All views | `#L` (large) |

### Naming Conventions
| Type | Pattern | Example |
|------|---------|---------|
| Interface view | `Z[I]_` | `ZI_SalesOrder` |
| Consumption view | `Z[C]_` | `ZC_SalesOrder` |
| Restricted reuse | `Z[R]_` | `ZR_SalesOrderItem` |
| Private view | `Z[P]_` | `ZP_SalesCalc` |
| Value help | `Z[I]_*VH` | `ZI_StatusVH` |
| Access control | Same as view | `ZI_SalesOrder` (DCL file) |
| Abstract entity | `Z[A]_` | `ZA_SalesOrderAction` |

### Common Issues
```
Missing key field             → Every view needs at least one key
Association without cardinality → Always specify [0..1], [1..1], [0..*], [1..*]
Hardcoded values in SELECT    → Use parameters or constants
@UI annotations on I_ view   → Move @UI to C_ (projection) layer
Missing WHERE clause on large tables → Add filter for performance
CAST without explicit type    → Always specify target type
```

### Performance Warnings
```
SELECT FROM <large_table> without WHERE  → Add restricting conditions
JOIN without ON condition                → Always specify join condition
UNION ALL with mismatched types          → Ensure compatible field types
Calculated field using string functions  → May prevent HANA pushdown
```

## Output
```
⚠ cds-validate: ZI_SalesOrder — Missing @AccessControl.authorizationCheck
⚠ cds-validate: ZI_SalesOrder — Association 'to_Items' missing cardinality
ℹ cds-validate: ZI_SalesOrder — Consider adding @ObjectModel.usageType annotations
```
