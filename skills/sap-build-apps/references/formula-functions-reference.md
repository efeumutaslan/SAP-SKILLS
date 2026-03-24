# SAP Build Apps — Formula Functions Reference

## Data Manipulation

| Function | Syntax | Example |
|----------|--------|---------|
| `MAP` | `MAP(list, item, expr)` | `MAP(data.Orders, item, item.amount)` |
| `SELECT` | `SELECT(list, item, condition)` | `SELECT(data.Orders, item, item.status == "open")` |
| `SORT` | `SORT(list, item, key)` | `SORT(data.Orders, item, item.date)` |
| `UNIQUE_BY_KEY` | `UNIQUE_BY_KEY(list, item, key)` | `UNIQUE_BY_KEY(data.Items, item, item.category)` |
| `SUM` | `SUM(list, item, expr)` | `SUM(data.Items, item, item.price * item.qty)` |
| `COUNT` | `COUNT(list)` | `COUNT(data.Orders)` |
| `FIND` | `FIND(list, item, cond)` | `FIND(data.Users, item, item.id == pageVars.userId)` |
| `REDUCE` | `REDUCE(list, acc, item, expr, init)` | `REDUCE(data.Items, acc, item, acc + item.total, 0)` |

## String Functions

| Function | Syntax | Result |
|----------|--------|--------|
| `UPPERCASE` | `UPPERCASE("hello")` | `"HELLO"` |
| `LOWERCASE` | `LOWERCASE("Hello")` | `"hello"` |
| `SUBSTRING` | `SUBSTRING("hello", 0, 3)` | `"hel"` |
| `CONTAINS` | `CONTAINS("hello world", "world")` | `true` |
| `REPLACE_ALL` | `REPLACE_ALL("a-b-c", "-", "/")` | `"a/b/c"` |
| `SPLIT` | `SPLIT("a,b,c", ",")` | `["a","b","c"]` |
| `TRIM` | `TRIM("  hello  ")` | `"hello"` |
| `FORMAT_LOCALIZED_DECIMAL` | `FORMAT_LOCALIZED_DECIMAL(1234.5, "en", 2)` | `"1,234.50"` |

## Date/Time

| Function | Example |
|----------|---------|
| `NOW()` | Current timestamp |
| `FORMAT_DATETIME_LOCAL(date, "DD.MM.YYYY")` | `"15.03.2025"` |
| `DATETIME_DIFFERENCE(d1, d2, "days")` | Days between dates |
| `ADD_DURATION(NOW(), 7, "days")` | Add 7 days |
| `SET_DATETIME_COMPONENT(date, 0, "hours")` | Set time to midnight |

## Logic & Conditions

```
// IF
IF(condition, trueValue, falseValue)
IF(data.Order.status == "approved", "✓", "pending")

// Nested IF
IF(score >= 90, "A", IF(score >= 80, "B", IF(score >= 70, "C", "F")))

// AND / OR / NOT
IF(AND(pageVars.isAdmin, data.Order.total > 1000), "Review", "Auto-approve")
IF(OR(status == "open", status == "in_progress"), true, false)

// IS_EMPTY
IF(IS_EMPTY(data.Orders), "No orders found", COUNT(data.Orders) + " orders")

// COALESCE (first non-empty)
COALESCE(data.User.nickname, data.User.firstName, "Unknown")
```

## OData Integration Formulas

```
// Build filter string
"$filter=Status eq '" + pageVars.selectedStatus + "' and Amount gt " + NUMBER(pageVars.minAmount)

// Expand navigation
"$expand=to_Items($select=Material,Quantity,Amount)"

// Dynamic endpoint
"/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrder('" + pageVars.orderId + "')"
```

## Page Variable Patterns

```
// Binding
pageVars.searchTerm

// Set via formula
SET_PAGE_VARIABLE("isLoading", true)

// App variable (global)
appVars.currentUser.email

// Flow function output
outputs["Get record"].record.Name
```
