# Segregation of Duties (SoD) Matrix

## Overview

SoD conflicts occur when a single user has access to incompatible business functions, creating
fraud or error risk. A typical enterprise SAP SoD matrix contains 100-300 rules.

## Critical SoD Conflicts

### Finance (FI)

| Function A | Transactions | Function B | Transactions | Risk Level | Risk |
|-----------|-------------|-----------|-------------|------------|------|
| Maintain GL Master | FS00, FSP0 | Post Journal Entry | FB50, FB01, F-02 | Critical | Financial misstatement |
| Maintain GL Master | FS00 | Execute Period Close | FAGLB03, S_ALR_87 | High | Manipulation of period-end |
| Post Vendor Invoice | FB60, MIRO | Approve Vendor Payment | F110 | Critical | Pay unauthorized invoices |
| Post Customer Credit | FB75, FB65 | Maintain Customer Master | XD01, XD02, BP | Critical | Fictitious credit fraud |
| Manage Bank Master | FI12 | Execute Payment Run | F110 | Critical | Redirect payments |
| Post Manual JE | FB50, FB01 | Reverse Document | FB08 | High | Cover fraudulent postings |

### Procurement (MM)

| Function A | Transactions | Function B | Transactions | Risk Level | Risk |
|-----------|-------------|-----------|-------------|------------|------|
| Create Vendor | XK01, MK01, BP | Post Vendor Payment | F110, F-53 | Critical | Fictitious vendor fraud |
| Create PO | ME21N | Approve PO | ME29N | Critical | Unauthorized procurement |
| Create PO | ME21N | Goods Receipt | MIGO | High | Receive goods for own POs |
| Maintain Source List | ME01 | Create PO | ME21N | High | Manipulate sourcing |
| Maintain Pricing | ME11, ME12 | Create PO | ME21N | High | Price manipulation |
| Create PO | ME21N | Post Vendor Invoice | MIRO, FB60 | High | Invoice for own POs |

### Sales (SD)

| Function A | Transactions | Function B | Transactions | Risk Level | Risk |
|-----------|-------------|-----------|-------------|------------|------|
| Maintain Customer Master | XD01, XD02, BP | Create Sales Order | VA01 | High | Sell to fictitious customer |
| Create Sales Order | VA01 | Create Delivery | VL01N | High | Ship unauthorized orders |
| Create Sales Order | VA01 | Create Billing | VF01 | High | Invoice manipulation |
| Maintain Pricing | VK11, VK12 | Create Sales Order | VA01 | High | Price manipulation |
| Process Credit Memo | VA01 (CR) | Maintain Customer Master | XD02 | Critical | Credit fraud |

### Human Resources (HR)

| Function A | Transactions | Function B | Transactions | Risk Level | Risk |
|-----------|-------------|-----------|-------------|------------|------|
| Create Employee | PA30, PA40 | Run Payroll | PC00_M99 | Critical | Ghost employee fraud |
| Maintain Pay Data | PA30 (IT0008) | Approve Payroll | PC00_M99 | Critical | Unauthorized pay changes |
| Maintain Bank Data | PA30 (IT0009) | Run Payroll | PC00_M99 | Critical | Redirect salary payments |
| Hire Employee | PA40 | Terminate Employee | PA40 | High | Unauthorized HR actions |

### Basis / Security

| Function A | Transactions | Function B | Transactions | Risk Level | Risk |
|-----------|-------------|-----------|-------------|------------|------|
| Maintain Users | SU01, SU10 | Maintain Roles | PFCG | Critical | Privilege escalation |
| Maintain Users | SU01 | Execute Sensitive Tcodes | Any critical tcode | Critical | Self-service access |
| ABAP Development | SE38, SE80 | Transport Release | SE09, SE10 | Critical | Inject code to production |
| Table Maintenance | SM30 | Change Logging Config | SE13 | Critical | Tamper with audit trail |
| RFC Destinations | SM59 | Program Execution | SA38 | High | External system abuse |

## S/4HANA-Specific Considerations

### Business Partner Consolidation
S/4HANA replaces separate vendor/customer masters with Business Partner (BP transaction).
SoD rules must be updated:
- Old: XK01 (Create Vendor) vs. F110 (Payment)
- New: BP (Create Business Partner with Vendor role) vs. F110 (Payment)

### Fiori App Consolidation
One Fiori app may combine functions that were separate transactions:
- "Manage Purchase Orders" app covers ME21N + ME22N + ME23N
- SoD rules must consider app-level access, not just transaction-level

### Authorization Object Changes
New authorization objects for OData services (S_SERVICE) and Fiori catalogs need SoD mapping.

## Mitigation Controls

When SoD conflicts cannot be eliminated, assign compensating controls:

| Control Type | Example | Frequency |
|-------------|---------|-----------|
| **Review** | Manager reviews all vendor master changes | Monthly |
| **Report** | Automated report of payment changes > threshold | Weekly |
| **Approval** | Dual approval for POs > $10,000 | Per transaction |
| **Monitoring** | Alert on changes to bank master data | Real-time |
| **Reconciliation** | Reconcile GR/IR clearing account | Monthly |

## Tools for SoD Analysis

| Tool | Description |
|------|-------------|
| **SAP GRC Access Control** | Enterprise SoD management with Access Risk Analysis (ARA) |
| **SUIM** | Built-in authorization reporting (limited SoD checks) |
| **SAP Cloud IAG** | Cloud-native GRC for hybrid landscapes |
| **Pathlock** | Third-party SoD and compliance tool |
| **SecurityBridge** | Third-party SAP security platform |
