# OData Query Options Cheatsheet

All OData query options with working examples. Covers v2 and v4 — differences marked.

## Table of Contents

- [$select — choose columns](#select--choose-columns)
- [$expand — include related entities](#expand--include-related-entities)
- [$filter — server-side filtering](#filter--server-side-filtering)
- [$orderby — sorting](#orderby--sorting)
- [$top / $skip — paging](#top--skip--paging)
- [$count — result count](#count--result-count)
- [$search — full-text search (v4)](#search--full-text-search-v4)
- [$apply — aggregations (v4)](#apply--aggregations-v4)
- [$format — response format](#format--response-format)
- [Combining options](#combining-options)
- [URL Encoding Quick Reference](#url-encoding-quick-reference)

## $select — choose columns

Reduces payload by returning only specified properties.

```http
GET /Products?$select=ID,Name,Price
```

**Nested select (inside $expand):**
```http
GET /Products?$expand=Supplier($select=Name,Country)
```

**Why it matters:** A `$select` on a 20-column table can reduce payload by 80%.

## $expand — include related entities

Embeds related navigation properties (like SQL JOIN).

```http
GET /Products?$expand=Supplier,Category
GET /Products?$expand=Supplier($select=Name)
GET /Products?$expand=Orders($filter=Status eq 'Open')       # v4
GET /Products?$expand=Supplier/Address                        # v2 nested path
GET /Products?$expand=Supplier($expand=Address)               # v4 nested expand
GET /Products('HT-1001')?$expand=Reviews($top=5;$orderby=Date desc)
```

**Deep expands are expensive** — prefer separate batch requests for more than 2 levels.

## $filter — server-side filtering

Logical expression evaluated on the server.

### Comparison operators
| Operator | Meaning | Example |
|----------|---------|---------|
| `eq` | Equal | `$filter=Name eq 'Widget'` |
| `ne` | Not equal | `$filter=Status ne 'Closed'` |
| `gt` | Greater than | `$filter=Price gt 100` |
| `ge` | Greater or equal | `$filter=Price ge 100` |
| `lt` | Less than | `$filter=Price lt 500` |
| `le` | Less or equal | `$filter=Price le 500` |

### Logical operators
```http
$filter=Price gt 100 and Category eq 'Electronics'
$filter=Category eq 'Electronics' or Category eq 'Furniture'
$filter=not (Status eq 'Closed')
$filter=(Price gt 100 and Stock gt 0) or Featured eq true
```

### String functions
| Function | v2 | v4 | Example |
|----------|----|----|---------|
| `contains` | ❌ | ✅ | `$filter=contains(Name, 'Pro')` |
| `substringof` | ✅ | ❌ | `$filter=substringof('Pro', Name)` |
| `startswith` | ✅ | ✅ | `$filter=startswith(Name, 'HT')` |
| `endswith` | ✅ | ✅ | `$filter=endswith(Name, '-X')` |
| `tolower` | ✅ | ✅ | `$filter=tolower(Name) eq 'widget'` |
| `toupper` | ✅ | ✅ | `$filter=toupper(Code) eq 'ABC'` |
| `length` | ✅ | ✅ | `$filter=length(Name) gt 10` |
| `indexof` | ✅ | ✅ | `$filter=indexof(Name, '-') ge 0` |
| `substring` | ✅ | ✅ | `$filter=substring(Name, 0, 3) eq 'HT-'` |
| `concat` | ✅ | ✅ | `$filter=concat(First, Last) eq 'JoeSmith'` |
| `trim` | ✅ | ✅ | `$filter=trim(Name) eq 'Widget'` |
| `matchesPattern` | ❌ | ✅ | `$filter=matchesPattern(Name, '^HT-.*')` |

### Date/time functions
| Function | Example |
|----------|---------|
| `year` | `$filter=year(CreatedAt) eq 2026` |
| `month` | `$filter=month(CreatedAt) eq 4` |
| `day` | `$filter=day(CreatedAt) eq 8` |
| `hour` | `$filter=hour(CreatedAt) lt 12` |
| `minute` | `$filter=minute(CreatedAt) eq 30` |
| `second` | `$filter=second(CreatedAt) eq 0` |
| `date` | `$filter=date(CreatedAt) eq 2026-04-08` (v4) |
| `now` | `$filter=CreatedAt gt now()` (v4) |

### Math functions
```http
$filter=round(Price) eq 100
$filter=floor(Price) eq 99
$filter=ceiling(Price) eq 100
```

### Filter on navigation properties
```http
# Single-valued navigation (to-one)
$filter=Supplier/Country eq 'DE'
$filter=Supplier/Name eq 'Acme'

# Multi-valued navigation (to-many) — v4 lambda operators
$filter=Orders/any(o: o/Status eq 'Open')
$filter=Orders/all(o: o/Amount gt 0)
$filter=Tags/any(t: t/Name eq 'featured')
```

### Collection filters (v4 `in` operator)
```http
$filter=Category in ('Electronics','Furniture','Clothing')
$filter=ID in ('HT-1001','HT-1002','HT-1003')
```

### Null checks
```http
$filter=Description eq null
$filter=Description ne null
```

### String literals with apostrophes
Double the apostrophe:
```http
$filter=Name eq 'O''Brien'
```

## $orderby — sorting

```http
$orderby=Name                       # ascending (default)
$orderby=Name asc                   # explicit ascending
$orderby=Price desc                 # descending
$orderby=Price desc, Name asc       # multi-column
$orderby=Supplier/Country asc       # navigation property
```

## $top / $skip — paging

```http
?$top=20                            # first 20 rows
?$top=20&$skip=40                   # rows 41-60
?$top=0&$count=true                 # only the count, no data
```

**Server-side paging limits:** Most SAP OData services cap `$top` at 5000. Use `growing` in UI5 to load in chunks.

## $count — result count

```http
# v4
GET /Products?$count=true
# Response: { "@odata.count": 1234, "value": [...] }

# v4 count-only
GET /Products/$count
# Response: 1234 (plain text)

# v2 — inline count with data
GET /Products?$inlinecount=allpages
# Response: { "d": { "__count": "1234", "results": [...] } }

# v2 — count only
GET /Products/$count
```

## $search — full-text search (v4)

Only works if the service declares `Capabilities.SearchRestrictions.Searchable: true`.

```http
$search=laptop
$search=laptop AND (gaming OR professional)
$search="exact phrase"
$search=-unwanted                   # exclusion
```

Most SAP-generated services do **not** enable search by default.

## $apply — aggregations (v4)

Aggregate on the server — no need to fetch raw rows.

```http
# Group by one column, sum another
?$apply=groupby((Category), aggregate(Price with sum as TotalPrice))

# Multiple measures
?$apply=groupby((Category),
                aggregate(Price with sum as Total,
                          Stock with average as AvgStock,
                          ID with countdistinct as ProductCount))

# Filter before grouping
?$apply=filter(Price gt 100)/groupby((Category), aggregate(Price with sum as TotalPrice))

# Having (filter after grouping)
?$apply=groupby((Category), aggregate(Price with sum as Total))/filter(Total gt 1000)

# Pipeline with $top/$orderby
?$apply=groupby((Category), aggregate(Price with sum as Total))&$orderby=Total desc&$top=10
```

**Aggregation functions:** `sum`, `min`, `max`, `average`, `countdistinct`

## $format — response format

```http
?$format=json                       # JSON (default for most clients)
?$format=xml                        # Atom XML
?$format=application/json           # full MIME type
```

Usually handled by `Accept` header instead:
```http
Accept: application/json
```

## Combining options

All options can be combined in a single URL:

```http
GET /Products?$select=ID,Name,Price,Stock
            &$expand=Supplier($select=Name,Country)
            &$filter=Price gt 100 and Category eq 'Electronics'
            &$orderby=Price desc
            &$top=20&$skip=0
            &$count=true
```

**Order of evaluation:**
1. `$filter` — narrow the set
2. `$orderby` — sort
3. `$skip` — offset
4. `$top` — limit
5. `$expand`, `$select` — projection
6. `$count` — count AFTER filters, BEFORE paging

## URL Encoding Quick Reference

| Character | Encoded |
|-----------|---------|
| space | `%20` |
| `'` | `%27` (rare, usually kept raw inside strings) |
| `"` | `%22` |
| `/` | `%2F` |
| `?` | `%3F` |
| `#` | `%23` |
| `&` | `%26` |
| `=` | `%3D` |
| `+` | `%2B` |

**In practice:** browsers and HTTP clients encode these automatically when you use `URLSearchParams` or equivalent.
