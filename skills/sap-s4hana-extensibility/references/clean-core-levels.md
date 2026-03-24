# Clean Core 4-Level Model — Deep Dive

## Overview

The 4-Level model (introduced August 2025) replaces the original 3-Tier model. It classifies
custom code by upgrade safety and cloud readiness.

## Level A: Fully Compliant

**Definition:** Uses only released APIs with C0/C1/C2 contracts. Built on-stack via ABAP Cloud
or side-by-side on BTP.

**Characteristics:**
- ABAP Cloud language version (restricted syntax)
- Only released SAP objects accessible
- ATC cloud readiness checks pass without findings
- Fully upgrade-safe across all S/4HANA editions

**Technical enforcement:**
- Software component language version: "ABAP Cloud"
- ATC check variant: `ABAP_CLOUD_READINESS` (from github.com/SAP/abap-atc-cr-cv-s4hc)
- Runtime: Non-released API calls blocked by the ABAP Cloud runtime

**What you CAN use:**
- Released CDS views (C1/C2)
- Released classes and interfaces (C1)
- Released BAdIs (C0)
- Released RAP business objects
- CDS view extensions (`EXTEND VIEW ENTITY`)
- RAP BO behavior extensions (`extend behavior for`)

**What you CANNOT use:**
- Function modules (even Z-custom ones)
- Include programs
- SAP GUI transactions (SE38, SE80, etc.)
- Direct database access to SAP tables
- Non-released SAP classes/interfaces
- Classic BAdIs (SE18/SE19)

## Level B: Compliant

**Definition:** Level A criteria plus classic APIs (BAPIs, standard BAdIs) that are documented
and generally upgrade-stable but not formally released with C1/C2 contracts.

**Characteristics:**
- May use "classic APIs" listed in SAP's classic API catalog
- These APIs are not in ABAP Cloud allowed list but are documented and widely used
- Generally survive upgrades but no formal contract guarantee
- The Tier 2 wrapper pattern bridges Level B to Level A

**Classic API list:** Maintained in the ATC check variant repository. Includes BAPIs like
BAPI_PO_CREATE1, BAPI_MATERIAL_GET_DETAIL, etc.

**When to use:** Transitional state — use Level B when Level A is not yet possible, but plan
to migrate to Level A when released successors become available.

## Level C: Partially Compliant

**Definition:** Accesses SAP internal objects not classified as classic APIs. Provides
flexibility for legacy scenarios but carries upgrade risk.

**Examples:**
- Reading from SAP internal tables via SELECT
- Using non-documented SAP function modules
- Calling SAP internal classes not in the classic API list
- Classic BAdI implementations (SE18/SE19) for non-released BAdIs

**Upgrade risk:** Medium to high. SAP may change internal tables, function module signatures,
or class interfaces without notice.

## Level D: Non-Compliant

**Definition:** Non-recommended patterns including modifications, direct writes to SAP tables,
implicit enhancements, and other invasive techniques.

**Examples:**
- Modifications to SAP standard code (modification assistant)
- Direct INSERT/UPDATE/DELETE on SAP standard tables
- Implicit enhancements (code injection at include boundaries)
- User exits via CMOD/SMOD (legacy enhancement framework)
- Kernel-level hooks

**Upgrade risk:** Very high. Almost guaranteed to break on upgrade.

## Migration Strategy: Moving Toward Level A

### Step 1: Assess
- Run ATC cloud readiness checks on all Z/Y custom code
- Categorize findings by level (A/B/C/D)
- Prioritize: Level D → C → B → A

### Step 2: Refactor Level D
- Remove modifications (replace with BAdIs or extensions)
- Remove direct SAP table writes (replace with BAPIs or released APIs)
- Remove implicit enhancements (replace with explicit BAdIs)

### Step 3: Wrap Level B/C
- Create Tier 2 wrapper classes for needed classic APIs
- Release wrapper interfaces with C1 contract
- Consume wrappers from Level A code

### Step 4: Monitor
- Check SAP's released API list quarterly (new releases may eliminate wrappers)
- Subscribe to SAP's API changelog notifications
- Use Cloudification Repository MCP server for automated checks

## ATC Check Variant Setup

```
1. Download latest check variant from github.com/SAP/abap-atc-cr-cv-s4hc
2. Import via transaction ATC → Check Variants → Import
3. Assign variant ABAP_CLOUD_READINESS to your development packages
4. Run: ADT → Right-click package → Run As → ABAP Test Cockpit
5. Review findings: each finding maps to a specific level (A/B/C/D)
```

## Nominated APIs

When a classic API has no released successor but is widely needed:
- SAP may "nominate" it for Tier 2 consumption
- List: github.com/SAP-samples/abap-platform-nominated-apis-consumption
- Nominated APIs are upgrade-stable but not formally C1-released
- They represent SAP's commitment to maintain the API until a C1 successor exists
