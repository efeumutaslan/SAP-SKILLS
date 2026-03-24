# Critical Authorization Objects — Full Reference

## System Administration

### S_TCODE — Transaction Code Authorization
```
Field: TCD (Transaction Code)
Check: Every transaction start
Risk: TCD = * grants ALL transactions
```
**Best practice:** Always list specific transaction codes; never use wildcards in production.

### S_TABU_DIS — Table Access via Authorization Groups
```
Fields: DICBERCLS (Auth Group), ACTVT (Activity)
Activities: 02 = Change, 03 = Display
Check: SE16, SM30, SM31, SE16N table access
Risk: DICBERCLS = * grants access to ALL table groups (HR/payroll data!)
```

### S_TABU_NAM — Table Access by Name
```
Field: TABLE (Table Name), ACTVT (Activity)
Check: Alternative to S_TABU_DIS for fine-grained control
Usage: Restrict access to specific tables by name
```
**Best practice:** Use S_TABU_NAM for targeted restrictions; S_TABU_DIS for group-based.

### S_DEVELOP — ABAP Development Authorization
```
Fields: DEVCLASS (Package), OBJTYPE (Object Type), OBJNAME (Object Name),
        P_GROUP (Auth Group), ACTVT (Activity)
Activities: 01=Create, 02=Change, 03=Display, 06=Delete
Risk: Must be PROHIBITED in production systems
```

### S_PROGRAM — Program Execution
```
Fields: P_ACTION (SUBMIT/BTCSUBMIT/VARIANT), P_GROUP (Auth Group)
Check: Controls report/program execution
Usage: Restrict which programs users can run
```

### S_ADMI_FCD — System Admin Functions
```
Field: S_ADMI_FCD (Function Code)
Values: PADM=Profile Admin, SPOS=Spool Admin, ST0M=System Monitor
Risk: Contains powerful system admin capabilities
```

## User & Role Administration

### S_USER_GRP — User Master Maintenance
```
Fields: CLASS (User Group), ACTVT (Activity)
Activities: 01=Create, 02=Change, 03=Display, 05=Lock/Unlock, 06=Delete, 22=Assign
Check: SU01, SU10 user maintenance
Risk: Activity 05 (unlock) can reactivate locked accounts
```

### S_USER_AGR — Role Assignment
```
Fields: ACT_GROUP (Role Name), ACTVT (Activity)
Activities: 01=Create, 02=Change, 03=Display, 22=Assign
Check: Who can assign which roles
Risk: ACT_GROUP = * lets admin assign ANY role (including SAP_ALL)
```

### S_USER_PRO — User Profile Assignment
```
Fields: PROFILE (Profile Name), ACTVT (Activity)
Check: Direct profile assignment (bypass PFCG)
Risk: Profile = SAP_ALL is the ultimate escalation
```

### S_USER_AUT — User Authorization Maintenance
```
Fields: OBJECT (Auth Object), AUTH (Authorization), ACTVT (Activity)
Check: Controls who can maintain authorizations for which objects
```

## RFC & Communication

### S_RFC — Remote Function Call
```
Fields: RFC_TYPE (Type), RFC_NAME (Name), ACTVT (Activity)
RFC_TYPE: FUGR=Function Group, FUNC=Function Module
ACTVT: 16=Execute
Check: FM/FUGR execution via RFC
Runtime: Checks FUGR first; if fail, checks FUNC
```

### S_ICF — Internet Communication Framework
```
Fields: ICF_FIELD (Check Type), ICF_VALUE (Value)
ICF_FIELD: SERVICE = ICF service path
Check: SICF service access (HTTP handlers, OData services)
```

### S_SERVICE — External Service Authorization
```
Fields: SRV_NAME (Service Name), SRV_TYPE (Type)
SRV_TYPE: HT=HTTP service
Check: Fiori app and OData service access
Critical for: S/4HANA Fiori launchpad authorization
```

## Financial Accounting (FI)

### F_BKPF_BUK — Accounting Document: Company Code
```
Fields: BUKRS (Company Code), ACTVT (Activity)
Check: FI document posting by company code
Activities: 01=Create, 02=Change, 03=Display
```

### F_BKPF_KOA — Accounting Document: Account Type
```
Fields: KOART (Account Type), ACTVT (Activity)
KOART: D=Customer, K=Vendor, S=GL Account, A=Asset, M=Material
Check: Which account types user can post to
```

### F_BKPF_BLA — Accounting Document: Document Type
```
Fields: BRGRU (Auth Group for Doc Type), ACTVT (Activity)
Check: Which document types user can create
```

### F_BKPF_GSB — Accounting Document: Business Area
```
Fields: GSBER (Business Area), ACTVT (Activity)
Check: FI posting by business area
```

## Materials Management (MM)

### M_BEST_BSA — Purchase Order: Document Type
```
Fields: BSART (PO Document Type), ACTVT (Activity)
Activities: 01=Create, 02=Change, 03=Display
Check: Which PO types the user can work with
```

### M_BEST_EKG — Purchase Order: Purchasing Group
```
Fields: EKGRP (Purchasing Group), ACTVT (Activity)
Check: Restrict PO access by purchasing group
```

### M_BEST_EKO — Purchase Order: Purchasing Organization
```
Fields: EKORG (Purchasing Organization), ACTVT (Activity)
Check: Restrict PO access by purchasing organization
```

### M_BEST_WRK — Purchase Order: Plant
```
Fields: WERKS (Plant), ACTVT (Activity)
Check: Restrict PO access by plant
```

## Sales & Distribution (SD)

### V_VBAK_VKO — Sales Document: Sales Organization
```
Fields: VKORG (Sales Organization), VTWEG (Distribution Channel),
        SPART (Division), ACTVT (Activity)
Check: Sales document access by sales area
```

### V_VBAK_AAT — Sales Document: Document Type
```
Fields: AUART (Sales Doc Type), ACTVT (Activity)
Check: Which sales document types user can create
```

## Human Resources (HR)

### P_ORGIN — HR Master Data
```
Fields: INFTY (Infotype), SUBTY (Subtype), AUTHC (Auth Level),
        PERSA (Personnel Area), PERSG (Employee Group), PERSK (Employee Subgroup),
        VDSK1 (Org Key)
AUTHC: R=Read, W=Write (includes Read), S=Write Lock, E=Enqueue Lock, D=Dequeue Lock, M=Matchcode
Check: Access to PA30/PA20 infotype data
Critical: Restricts access to sensitive data (salary, bank details, etc.)
```

### P_PERNR — HR Master Data: Personnel Number Check
```
Fields: PSIGN (Include/Exclude), INFTY (Infotype), SUBTY (Subtype), AUTHC (Auth Level)
Check: Restricts access based on the personnel number itself
Usage: Combined with P_ORGIN for layered security
```

## Activity Code Reference

| Activity | Meaning | Code |
|----------|---------|------|
| Create | Create new objects | 01 |
| Change | Modify existing objects | 02 |
| Display | Read-only access | 03 |
| Print | Print/spool output | 04 |
| Lock/Unlock | Lock or unlock records | 05 |
| Delete | Delete objects | 06 |
| Activate | Activate configurations | 07 |
| Display Changes | View change history | 08 |
| Execute | Execute programs/functions | 16 |
| Assign | Assign roles/profiles | 22 |
| Archive | Archive data | 26 |

## Building Custom Authorization Objects

### When to Create Custom Objects
- Standard objects don't cover your authorization needs
- Custom Z-transactions need specific field-level checks
- Custom fields in standard processes need authorization

### Creation Steps (SU21)
```
1. SU21 → Create new authorization object
2. Object name: Z_<MODULE>_<NAME> (e.g., Z_FI_PROJAUTH)
3. Object class: Z<CLASS> (create if needed)
4. Add fields:
   - ACTVT (Activity) — standard, always include
   - Z_PROJID (Project ID) — custom field
   - Z_REGION (Region) — custom field
5. Max 10 fields per object
6. Activate
```

### Check in ABAP Code
```abap
AUTHORITY-CHECK OBJECT 'Z_FI_PROJAUTH'
  ID 'ACTVT'    FIELD '02'          " Change
  ID 'Z_PROJID' FIELD lv_project_id
  ID 'Z_REGION' FIELD lv_region.

IF sy-subrc <> 0.
  RAISE EXCEPTION TYPE zcx_unauthorized.
ENDIF.
```

### Register in SU24
```
SU24 → Enter custom transaction ZFI_PROJECT
→ Add object Z_FI_PROJAUTH
→ Set check indicator: "Check"
→ Set proposal values for PFCG
```
