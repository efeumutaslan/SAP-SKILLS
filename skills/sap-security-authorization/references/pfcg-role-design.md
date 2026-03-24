# PFCG Role Design — Complete Guide

## Table of Contents
- [Role Design Workflow](#role-design-workflow) | [PFCG Tab-by-Tab](#pfcg-tab-by-tab-guide)
- [Naming Convention](#role-naming-convention) | [Master/Derived Pattern](#masterderived-role-pattern)
- [SU24 Maintenance](#su24-maintenance) | [Composite Roles](#composite-role-design)
- [S/4HANA Cloud Roles](#s4hana-cloud-business-roles) | [Testing](#testing-roles) | [Common Mistakes](#common-mistakes)

## Role Design Workflow

```
1. Analyze Business Requirements
   → What transactions/apps does the user need?
   → What org-level restrictions apply?

2. Check SU24 Defaults
   → Which auth objects are proposed for each transaction?
   → Adjust check indicators if needed

3. Create Master Role in PFCG
   → Add transactions to Menu tab
   → Switch to Authorizations tab
   → Maintain field values (green = maintained, yellow = needs attention, red = missing)
   → Generate profile

4. Create Derived Roles (if multi-org)
   → Inherit from master
   → Only change org-level values

5. Test with SU53 / STAUTHTRACE
   → Assign to test user
   → Execute business processes
   → Analyze failures

6. Transport to Target Systems
   → Role transport via SCC1 or PFCG export/import
```

## PFCG Tab-by-Tab Guide

### Tab 1: Description
- Role name: `Z_<MODULE>_<FUNCTION>_<TYPE>` (S=Single, C=Composite, D=Derived)
- Description: Clear business description (e.g., "FI Accounts Payable Clerk")

### Tab 2: Menu
Add transactions, Fiori apps, URLs, or folders:
```
Menu → Transaction → Enter: ME21N, ME22N, ME23N
Menu → SAP Fiori Launchpad → Tile Catalog: SAP_MM_PUR_MANAGE_PO
```

**Tip:** Use folders to organize menu items by business function.

### Tab 3: Authorizations
After adding menu items, click **Propose Profile Values**:
- System reads SU24 entries for each transaction
- Proposes authorization objects with default values
- You must review and maintain values (especially org-level fields)

**Traffic light system:**
| Color | Meaning | Action |
|-------|---------|--------|
| Green | All field values maintained | OK, review for correctness |
| Yellow | Some fields need values | Click to expand and maintain |
| Red | Critical fields missing | Must maintain before generation |

**Key maintenance actions:**
- Click field → enter specific values (e.g., Company Code: 1000, 2000)
- Click field → `*` for all values (use with caution!)
- Click "Org Levels" button → maintain organizational level values centrally

### Tab 4: User (Assignment)
- Assign users directly or via SU01
- Set validity period (From/To dates)
- Composite role assignment cascades single roles to user

### Tab 5: MiniApps (S/4HANA)
- Shows Fiori app tiles assigned through business catalogs
- View only; maintain via Menu tab or Business Catalogs

## Role Naming Convention

```
Pattern: Z_<MODULE>_<FUNCTION>_<TYPE>

MODULE: FI, CO, MM, SD, PP, HR, PM, QM, BC, BW, ...
FUNCTION: Short description of role purpose
TYPE: S = Single, C = Composite, D = Derived, T = Technical

Examples:
Z_FI_AP_CLERK_S          — FI Accounts Payable Clerk (single)
Z_FI_AP_CLERK_D_1000     — Derived for company code 1000
Z_FI_AP_TEAM_C           — Composite: AP Clerk + related roles
Z_MM_PO_APPROVER_S       — MM Purchase Order Approver (single)
Z_BC_RFC_INTEGRATION_T   — Technical role for RFC connections
Z_SD_SALES_OPS_S         — SD Sales Operations (single)
```

## Master/Derived Role Pattern

### When to Use
- Same job function across multiple organizational units
- Only org-level values differ (company code, plant, sales org, etc.)

### How It Works
```
Z_FI_AP_CLERK_S (Master)
├── Menu: FB60, F110, FBL1N, ...
├── Auth Objects: S_TCODE, F_BKPF_BUK, F_BKPF_KOA, ...
├── Org Levels: ★ = "to be maintained in derived roles"
│
├── Z_FI_AP_CLERK_D_1000 (Derived)
│   └── Org Level: BUKRS = 1000
│
├── Z_FI_AP_CLERK_D_2000 (Derived)
│   └── Org Level: BUKRS = 2000
│
└── Z_FI_AP_CLERK_D_3000 (Derived)
    └── Org Level: BUKRS = 3000
```

### Rules
1. NEVER add/remove transactions in derived roles (always in master)
2. ONLY change org-level values in derived roles
3. After changing master: open each derived role → Adjust button (Ctrl+F5)
4. Regenerate profiles for all derived roles after master change

## SU24 Maintenance

### Why SU24 Matters
SU24 controls which auth objects PFCG auto-proposes when you add a transaction to a role.
Without correct SU24 entries, role creators miss needed auth objects.

### When to Maintain SU24
- Creating custom Z-transactions
- Overriding SAP defaults for standard transactions
- After upgrades (use SU25 to reconcile)

### SU24 Procedure
```
1. SU24 → Enter transaction code (e.g., ZMM_REPORT)
2. Add authorization objects needed:
   - S_TCODE (automatic)
   - Z_MM_ORG (custom auth object)
   - S_TABU_DIS (if table access needed)
3. Set check indicator:
   - "Check" = object is checked at runtime
   - "No Check" = object exists but not checked
   - "Do Not Check" = suppress check entirely
4. Set proposal values (default field values for PFCG)
5. Save
```

### Tables
| Table | Purpose |
|-------|---------|
| USOBT | SAP standard defaults (transaction → auth object mapping) |
| USOBT_C | Customer modifications of USOBT |
| USOBX | SAP standard check indicators |
| USOBX_C | Customer modifications of USOBX |

## Composite Role Design

```
Z_FI_AP_TEAM_C (Composite)
├── Z_FI_AP_CLERK_S         — Invoice processing
├── Z_FI_AP_PAYMENT_S       — Payment execution
├── Z_FI_REPORTING_S        — Financial reports
└── Z_BC_FIORI_BASIC_S      — Basic Fiori catalog access
```

**Rules:**
- Composite roles contain NO authorization data themselves
- They are containers that group single roles
- Assigning composite = assigning all contained single roles
- SoD analysis must check across composite contents

## S/4HANA Cloud: Business Roles

In S/4HANA Cloud Public Edition, PFCG is replaced by Fiori-based IAM:

### Key Concepts
| On-Premise (PFCG) | Cloud (IAM) |
|-------------------|-------------|
| Transaction codes | Fiori apps (IAM apps) |
| Authorization objects + fields | Restriction Types |
| Single role | Business Role |
| Profile generation | Automatic |
| SU24 | Built-in to IAM app catalog |

### Business Role Creation
1. Open **Maintain Business Roles** Fiori app
2. Create new business role
3. Add **Business Catalogs** (pre-grouped app collections)
4. Configure **Restriction Types** (org-level equivalents)
5. Assign to users

### Restriction Types
| Category | Examples |
|----------|---------|
| Read Access | Read data for company code 1000 |
| Write Access | Write data for plant 0001 |
| Value Help | Show value help for specific org units |

### Business Catalog Examples
| Catalog ID | Description |
|-----------|-------------|
| SAP_MM_PUR_PO_MANAGE | Manage Purchase Orders |
| SAP_FI_GL_JE_POST | Post General Ledger Journal Entries |
| SAP_SD_SLS_SO_MNG | Manage Sales Orders |
| SAP_HR_EC_EMP_MNG | Manage Employee Master Data |

## Testing Roles

### Quick Test: SU53
```
1. Assign role to test user
2. User executes the transaction/app
3. If "No authorization" → user runs SU53 immediately
4. SU53 shows exact auth object and field that failed
5. Fix the role and retest
```

### Detailed Test: STAUTHTRACE
```
1. STAUTHTRACE → Activate trace for specific user
2. Option: "Trace for errors only" (reduces volume)
3. User reproduces the business process
4. STAUTHTRACE → Deactivate → Evaluate
5. Shows ALL auth checks: object, field, value, result (RC=0 pass, RC≠0 fail)
6. Export to Excel for role comparison
```

### Bulk Validation: SUIM
```
SUIM → Reports:
- "Users by Complex Selection Criteria" → find users with dangerous profiles
- "Roles by Complex Selection Criteria" → audit role contents
- "Auth Objects by Complex Criteria" → find where specific auth is granted
- "Comparison" → compare roles side-by-side
```

## Common Mistakes

1. **Granting `*` to S_TCODE** — allows ALL transactions
2. **Forgetting to regenerate profile** after role changes
3. **Editing derived roles directly** instead of the master
4. **Not running SU25 after upgrade** — missing new auth defaults
5. **Copying roles instead of deriving** — creates maintenance nightmare
6. **Not documenting role purpose** — unclear ownership and review
7. **Assigning too many roles** — creates SoD conflicts; use composites
