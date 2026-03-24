# SAP Role Naming Convention Template

## Pattern
```
Z_<MODULE>_<FUNCTION>_<TYPE>[_<ORG>]
```

## Components

| Part | Values | Description |
|------|--------|-------------|
| Prefix | `Z_` | Customer namespace |
| MODULE | FI, CO, MM, SD, PP, HR, PM, QM, WM, PS, BC, BW, CRM, SRM | SAP module code |
| FUNCTION | Short name (max 15 chars) | Business function |
| TYPE | S, C, D, T | S=Single, C=Composite, D=Derived, T=Technical |
| ORG | Optional org identifier | Company code, plant, etc. |

## Examples

### Finance (FI)
```
Z_FI_AP_CLERK_S              — Accounts Payable Clerk
Z_FI_AP_CLERK_D_1000         — Derived: Company Code 1000
Z_FI_AP_CLERK_D_2000         — Derived: Company Code 2000
Z_FI_AP_TEAM_C               — Composite: AP Clerk + Payment + Reports
Z_FI_AR_CLERK_S              — Accounts Receivable Clerk
Z_FI_GL_ACCOUNTANT_S         — General Ledger Accountant
Z_FI_AA_ADMIN_S              — Asset Accounting Admin
Z_FI_REPORTING_S             — FI Reporting (display only)
```

### Materials Management (MM)
```
Z_MM_PO_CREATOR_S            — Purchase Order Creator
Z_MM_PO_APPROVER_S           — Purchase Order Approver
Z_MM_BUYER_S                 — Buyer (full procurement cycle)
Z_MM_GR_CLERK_S              — Goods Receipt Clerk
Z_MM_INV_MGMT_S              — Inventory Management
Z_MM_VENDOR_ADMIN_S          — Vendor Master Maintenance
```

### Sales & Distribution (SD)
```
Z_SD_SALES_OPS_S             — Sales Order Processing
Z_SD_SALES_OPS_D_1000        — Derived: Sales Org 1000
Z_SD_DELIVERY_S              — Delivery Processing
Z_SD_BILLING_S               — Billing
Z_SD_PRICING_ADMIN_S         — Pricing Administration
Z_SD_CREDIT_MGMT_S           — Credit Management
```

### Basis / Security (BC)
```
Z_BC_USER_ADMIN_S            — User Administration
Z_BC_ROLE_ADMIN_S            — Role Administration
Z_BC_TRANSPORT_S             — Transport Management
Z_BC_FIORI_BASIC_S           — Basic Fiori Launchpad Access
Z_BC_RFC_INTEGRATION_T       — Technical: RFC Communication
Z_BC_BATCH_JOB_T             — Technical: Background Job Execution
Z_BC_MONITORING_S            — System Monitoring
```

### Human Resources (HR)
```
Z_HR_PA_CLERK_S              — Personnel Administration Clerk
Z_HR_PA_CLERK_D_US           — Derived: US Personnel Area
Z_HR_PAYROLL_S               — Payroll Processing
Z_HR_TIME_ADMIN_S            — Time Management
Z_HR_RECRUITING_S            — Recruiting
Z_HR_MANAGER_S               — Manager Self-Service
Z_HR_ESS_S                   — Employee Self-Service
```

## BTP Role Collection Naming

```
Pattern: <AppName>_<Role>

Examples:
MyApp_Viewer                  — Read-only access
MyApp_Editor                  — Read + write access
MyApp_Admin                   — Full administrative access
TravelApp_TravelProcessor     — Process travel requests
TravelApp_TravelApprover      — Approve travel requests
```

## S/4HANA Cloud Business Role Naming

```
Pattern: Z_BR_<MODULE>_<FUNCTION>

Examples:
Z_BR_FI_AP_CLERK             — Business Role: AP Clerk
Z_BR_MM_PROCUREMENT           — Business Role: Procurement
Z_BR_SD_SALES_OPS            — Business Role: Sales Operations
```
