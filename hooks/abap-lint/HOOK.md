---
name: abap-lint
description: ABAP code quality check hook. Triggers on .abap file save. Checks for common anti-patterns, naming conventions, and code quality issues.
trigger: file-save
file-patterns: ["*.abap"]
---

# ABAP Lint Hook

Automatically checks ABAP code quality when `.abap` files are saved.

## Rules

### Naming Conventions
| Object | Pattern | Example |
|--------|---------|---------|
| Class | `ZCL_` / `ZIF_` / `ZCX_` | `ZCL_ORDER_HANDLER` |
| Method | lowercase or camelCase | `get_orders`, `getOrders` |
| Variable (local) | `lv_`, `lt_`, `ls_`, `lr_`, `lo_` | `lv_count`, `lt_orders` |
| Variable (instance) | `mv_`, `mt_`, `ms_`, `mr_`, `mo_` | `mv_status` |
| Parameter (import) | `iv_`, `it_`, `is_`, `ir_`, `io_` | `iv_customer_id` |
| Parameter (export) | `ev_`, `et_`, `es_`, `er_`, `eo_` | `et_results` |
| Parameter (return) | `rv_`, `rt_`, `rs_`, `rr_`, `ro_` | `rv_count` |
| Constant | `c_` or `mc_` | `c_status_active` |

### Anti-Patterns to Detect
```
SELECT * FROM ...          → Specify needed columns only
SELECT SINGLE * FROM ...   → Specify needed columns
LOOP AT ... WHERE (nested) → Use FILTER or secondary table key
APPEND + SORT + DELETE ADJ → Use SORTED TABLE or hashed
CATCH cx_root              → Catch specific exceptions
TRY without CATCH          → Always handle exceptions
Empty method body          → Remove or implement
```

### Complexity Checks
- Method > 100 lines → Suggest splitting
- Nesting depth > 4 → Suggest extracting method
- Cyclomatic complexity > 10 → Suggest simplification
- Class > 1000 lines → Suggest decomposition

## Output
When issues found, display inline warnings:
```
⚠ abap-lint: line 42 — SELECT * detected, specify column list
⚠ abap-lint: line 88 — Method 'process_data' is 150 lines (max: 100)
⚠ abap-lint: line 15 — Variable 'x' does not follow naming convention (expected: lv_*)
```
