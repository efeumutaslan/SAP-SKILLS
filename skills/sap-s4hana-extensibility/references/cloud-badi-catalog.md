# Cloud BAdI Catalog & Implementation Guide

## Finding Released Cloud BAdIs

### Method 1: SAP API Business Hub
- URL: api.sap.com → Package: S4HANACloudBADI
- Browse by business area (Procurement, Sales, Finance, etc.)
- Each BAdI entry shows: interface, methods, parameters, filter values

### Method 2: ADT Released Objects
- Project Explorer → Released Objects node
- Filter by object type: BADI (BAdI Definition)
- Shows all BAdIs released for ABAP Cloud consumption

### Method 3: Custom Logic Fiori App (F6957)
- Lists BAdIs available for key-user implementation
- Grouped by business context (Purchase Requisition, Sales Order, etc.)
- Simpler implementation (no class definition needed)

### Method 4: Extensibility Cockpit
- Shows 180+ business contexts enabled for extension
- Links to available BAdIs per context

## Key Released BAdIs by Module

### Procurement (MM)
| Enhancement Spot | BAdI Definition | Interface | Purpose |
|-----------------|-----------------|-----------|---------|
| MM_PUR_S4_PR | MM_PUR_S4_PR_CHECK | IF_MM_PUR_S4_PR_CHECK | Validate purchase requisitions |
| MM_PUR_S4_PR | MM_PUR_S4_PR_MODIFY_ITEM | IF_MM_PUR_S4_PR_MODIFY_ITEM | Modify PR item data |
| MM_PUR_S4_PO | MM_PUR_S4_PO_CHECK | IF_MM_PUR_S4_PO_CHECK | Validate purchase orders |
| MM_PUR_S4_PO | MM_PUR_S4_PO_MODIFY | IF_MM_PUR_S4_PO_MODIFY | Modify PO data |

### Sales (SD)
| Enhancement Spot | BAdI Definition | Interface | Purpose |
|-----------------|-----------------|-----------|---------|
| SD_SLS | SD_SLS_FINALIZE | IF_SD_SLS_FINALIZE | Modify sales doc before save |
| SD_SLS | SD_SLS_FIELDPROP_ITEM | IF_SD_SLS_FIELDPROP_ITEM | Control field properties |
| SD_SLS | SD_SLS_CHECK | IF_SD_SLS_CHECK | Validation checks |

### Finance (FI)
| Enhancement Spot | BAdI Definition | Interface | Purpose |
|-----------------|-----------------|-----------|---------|
| FI_JRNL | FI_JRNL_ENTRY_CHECK | IF_FI_JRNL_ENTRY_CHECK | Validate journal entries |
| FI_AP | FI_AP_MODIFY | IF_FI_AP_MODIFY | Modify AP document |

## Implementation Steps (Developer Extensibility in ADT)

### Step 1: Create Enhancement Implementation
```
ADT → New → Other ABAP Repository Object
    → Enhancements → BAdI Enhancement Implementation
    → Enter name: ZEI_<YOUR_NAME>
    → Select Enhancement Spot (e.g., MM_PUR_S4_PR)
    → Select BAdI Definition (e.g., MM_PUR_S4_PR_CHECK)
```

### Step 2: Create Implementation Class
```abap
CLASS zcl_my_badi DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_badi_interface.
    INTERFACES if_mm_pur_s4_pr_check.  " The BAdI-specific interface
ENDCLASS.

CLASS zcl_my_badi IMPLEMENTATION.
  METHOD if_mm_pur_s4_pr_check~check.
    " Your validation logic here
    " Use 'reported' parameter to return messages
    " Use 'failed' parameter to mark items as failed
  ENDMETHOD.
ENDCLASS.
```

### Step 3: Activate
- Activate both the enhancement implementation and the class
- No additional registration needed — the framework discovers active implementations

### Step 4: Test
- Execute the business process (e.g., create a purchase requisition)
- Set breakpoints in ADT to debug
- Check message output for validation messages

## Implementation via Key-User (Custom Logic App)

### Step 1: Open Custom Logic App (F6957)
### Step 2: Select Business Context
- e.g., "Purchase Requisition" → shows available BAdIs
### Step 3: Choose BAdI and Write Script
```abap
" Simplified syntax — no class definition needed
IF purchaserequisitionitem-purchasingroup IS INITIAL.
  result = VALUE #( BASE result
    ( %tky = purchaserequisitionitem-%tky
      %msg = new_message( id = 'ZMM' number = '001'
                          severity = if_abap_behv_message=>severity-error ) ) ).
ENDIF.
```
### Step 4: Publish

## Cloud BAdI vs. Classic BAdI Comparison

| Aspect | Classic BAdI (SE18/SE19) | Cloud BAdI (ABAP Cloud) |
|--------|--------------------------|------------------------|
| Tool | SAP GUI | ADT or Custom Logic app |
| Language version | Unrestricted ABAP | ABAP Cloud (restricted) |
| Available in Public Cloud | No | Yes |
| Release contract | None | C0 (Extensibility) |
| Filter-based routing | Limited | Full support |
| Multiple implementations | Framework-dependent | Yes |
| Debugging | SAP GUI Debugger | ADT Debugger |

## Troubleshooting

**BAdI not triggered:**
1. Check enhancement implementation is activated
2. Verify filter values match (if BAdI uses filters)
3. Confirm the correct BAdI definition is implemented (some have similar names)
4. Check the business process actually reaches the extension point

**"Object not released" error:**
1. The BAdI definition might not be released for ABAP Cloud
2. Check Properties → API State in ADT
3. Only BAdIs with C0 contract are usable in ABAP Cloud

**Debugging tips:**
1. Set breakpoint in ADT on the BAdI method
2. Execute the business process via Fiori app
3. ADT Debugger will catch the breakpoint
4. Inspect importing parameters to understand the data context
