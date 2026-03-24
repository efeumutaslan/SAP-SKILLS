# S/4HANA Simplification Items — Quick Reference

## High-Impact Table Changes

| Legacy Table | S/4HANA Replacement | Impact |
|-------------|---------------------|--------|
| BSEG, BSIS, BSAS, BSID, BSAD, BSIK, BSAK | ACDOCA (Universal Journal) | All FI line items in single table |
| BKPF + BSEG | ACDOCA | Header+item merged |
| COEP, COBK | ACDOCA | CO line items moved |
| MBEW | MATVAL view on ACDOCA | Material valuation |
| KONV | PRCD_ELEMENTS | Pricing conditions |
| VBFA | Simplified, some flows removed | Document flow |
| LIPS | Delivery item (restructured) | Field changes |
| EKBE | History table (restructured) | GR/IR fields |

## Removed/Replaced Transactions

| Old Tcode | Replacement | Notes |
|-----------|-------------|-------|
| ME21N/ME22N/ME23N | Fiori: Manage Purchase Orders | Still works but Fiori preferred |
| VA01/VA02/VA03 | Fiori: Manage Sales Orders | Still works |
| FB01/FB02/FB03 | Fiori: Post/Display Journal Entry | Still works |
| F-28 (Incoming Payment) | Fiori: Post Incoming Payment | Still works |
| MM01/MM02/MM03 | Fiori: Manage Product Master | BP integration |
| XD01/XK01 (Customer/Vendor) | BP transaction | **Mandatory migration to BP** |
| VD01/MK01 | BP transaction | **Removed** |
| IW21/IW31 | Fiori: Maintain Notification/Order | PM/CS simplified |

## Mandatory Conversions

### Business Partner (Customer/Vendor → BP)
- All customer masters (KNA1, KNB1, KNVV) → BP tables (BUT000, BUT020)
- All vendor masters (LFA1, LFB1) → BP tables
- CVI (Customer Vendor Integration) must be active
- Dual maintenance: XD/XK still work but write to BP tables

### Material Ledger → Mandatory
- Always active in S/4HANA
- MBEW valuation through ML
- Actual costing: optional but ML tables always populated

### Credit Management → FIN-FSCM-CR
- Old VKM3/VKM4 replaced by Fiori apps
- UKM_* tables replace KNKK

## Custom Code Impact Categories

| Category | Action Required | Effort |
|----------|----------------|--------|
| SELECT from removed table | Change to new table/CDS view | High |
| INSERT/UPDATE removed table | Use new API/BAPI | High |
| Deprecated BAPI | Switch to released API | Medium |
| Removed function module | Find replacement | Medium |
| Changed data element/domain | Adjust types | Low |
| Removed screen field | UI adaptation | Low |

## Key CDS Views Replacing Direct Table Access

| Legacy Access | CDS View | API |
|--------------|----------|-----|
| SELECT FROM BSEG | I_JournalEntry | API_JOURNALENTRY_SRV |
| SELECT FROM EKKO/EKPO | I_PurchaseOrder | API_PURCHASEORDER_PROCESS_SRV |
| SELECT FROM VBAK/VBAP | I_SalesOrder | API_SALES_ORDER_SRV |
| SELECT FROM MARA/MARC | I_Product | API_PRODUCT_SRV |
| SELECT FROM KNA1 | I_BusinessPartner | API_BUSINESS_PARTNER |

## Pre-Migration Checks

```sql
-- Count custom code using removed tables (in SCI/ATC)
-- Priority 1: Direct DB access to removed tables
-- Priority 2: Deprecated BAPIs
-- Priority 3: Changed field lengths/types
```

### Tools
- **Simplification Database**: `https://me.sap.com/processnavigator` (search simplification items)
- **Custom Code Migration Worklist**: Transaction `SYCM` or Fiori app
- **Readiness Check**: SAP Readiness Check 2.0 via SAP for Me
- **ATC Check Variant**: `FUNCTIONAL_DB` and `FUNCTIONAL_DB_ADDITION`
