---
name: sap-signavio
description: >
  SAP Signavio process management and mining skill. Use when modeling BPMN 2.0 processes,
  running process mining (Process Intelligence), configuring process KPIs, or integrating
  Signavio with S/4HANA and SBPA. If the user mentions Signavio, process mining, BPMN
  modeling, conformance checking, or process transformation, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Signavio Process Management & Mining

## Related Skills
- `sap-build-process-automation` — Automate processes modeled in Signavio
- `sap-s4hana-extensibility` — Process variants for S/4HANA scenarios
- `sap-cloud-alm` — ALM process monitoring complements Signavio insights

## Quick Start

**Choose your Signavio component:**

| Component | Purpose | Key Activity |
|-----------|---------|-------------|
| **Process Manager** | BPMN modeling, process repository | Design & publish processes |
| **Process Intelligence** | Process mining, conformance | Analyze event logs |
| **Process Governance** | Approval workflows for models | Govern process changes |
| **Collaboration Hub** | Stakeholder communication | Share & collect feedback |
| **Journey Modeler** | Customer/employee journeys | Map experience flows |

**First API call — List Process Models:**

```bash
curl -X GET "https://editor.signavio.com/p/revision" \
  -H "x-signavio-id: {{SESSION_TOKEN}}" \
  -H "Accept: application/json" \
  -b "JSESSIONID={{SESSION_COOKIE}}"
```

## Core Concepts

### BPMN 2.0 Modeling Standards
| Element | Symbol | Usage |
|---------|--------|-------|
| Start Event | ○ | One per process (normal flow) |
| End Event | ◉ | At least one; use multiple for different outcomes |
| User Task | ▭ (person) | Manual human activity |
| Service Task | ▭ (gear) | Automated system call |
| Exclusive Gateway | ◇ (X) | Either/or branching |
| Parallel Gateway | ◇ (+) | Fork/join concurrent paths |
| Intermediate Event | ◎ | Timer, message, signal mid-flow |
| Subprocess | ▭ [+] | Encapsulate reusable process |

### Process Intelligence (Mining) Pipeline
1. **Data extraction** — Pull event logs from source systems (S/4HANA, ECC, SuccessFactors)
2. **Data transformation** — Map to Signavio event log format (Case ID, Activity, Timestamp)
3. **Process discovery** — Auto-generate process model from event data
4. **Conformance checking** — Compare discovered vs. designed process
5. **Root cause analysis** — Identify bottlenecks, rework loops, deviations
6. **KPI monitoring** — Track cycle time, throughput, automation rate

### Event Log Format
```csv
CaseID,Activity,Timestamp,Resource,Variant
PO-001,Create Purchase Requisition,2026-01-15T08:00:00Z,User_A,Standard
PO-001,Approve Purchase Requisition,2026-01-15T09:30:00Z,Manager_B,Standard
PO-001,Create Purchase Order,2026-01-15T10:00:00Z,System,Standard
PO-001,Goods Receipt,2026-01-20T14:00:00Z,User_C,Standard
PO-001,Invoice Receipt,2026-01-22T11:00:00Z,User_D,Standard
PO-001,Payment,2026-01-25T16:00:00Z,System,Standard
```

## Common Patterns

### Pattern 1: Signavio API Authentication

```python
import requests

SIGNAVIO_URL = "https://editor.signavio.com"

def authenticate(email, password, tenant_id):
    """Authenticate and get session token."""
    resp = requests.post(
        f"{SIGNAVIO_URL}/p/login",
        data={
            "name": email,
            "password": password,
            "tenant": tenant_id,
            "tokenonly": "true"
        }
    )
    resp.raise_for_status()
    return {
        "token": resp.text.strip(),
        "cookie": resp.cookies.get("JSESSIONID")
    }

def get_headers(session):
    return {
        "x-signavio-id": session["token"],
        "Accept": "application/json",
        "Cookie": f"JSESSIONID={session['cookie']}"
    }
```

### Pattern 2: Export BPMN Model

```python
def export_bpmn_xml(session, model_id):
    """Export process model as BPMN 2.0 XML."""
    headers = get_headers(session)
    resp = requests.get(
        f"{SIGNAVIO_URL}/p/revision/{model_id}/bpmn2_0_xml",
        headers=headers
    )
    resp.raise_for_status()
    return resp.text

def export_svg(session, model_id):
    """Export process diagram as SVG."""
    headers = get_headers(session)
    headers["Accept"] = "image/svg+xml"
    resp = requests.get(
        f"{SIGNAVIO_URL}/p/revision/{model_id}/svg",
        headers=headers
    )
    resp.raise_for_status()
    return resp.text
```

### Pattern 3: Process Mining Data Preparation (S/4HANA P2P)

```sql
-- CDS view for Procure-to-Pay event log extraction
@AbapCatalog.sqlViewName: 'ZV_P2P_EVLOG'
@Analytics: { dataCategory: #FACT }
define view Z_P2P_EVENT_LOG as

  -- Purchase Requisition Created
  select from eban {
    cast(banfn as abap.char(20)) as CaseID,
    'Create Purchase Requisition' as Activity,
    badat as EventTimestamp,
    ernam as Resource,
    bsart as Variant
  }
  union all
  -- Purchase Order Created
  select from ekko {
    cast(ebeln as abap.char(20)) as CaseID,
    'Create Purchase Order' as Activity,
    aedat as EventTimestamp,
    ernam as Resource,
    bsart as Variant
  }
  union all
  -- Goods Receipt
  select from mkpf
    inner join mseg on mkpf.mblnr = mseg.mblnr
                   and mkpf.mjahr = mseg.mjahr {
    cast(mseg.ebeln as abap.char(20)) as CaseID,
    'Goods Receipt' as Activity,
    mkpf.budat as EventTimestamp,
    mkpf.usnam as Resource,
    mseg.bwart as Variant
  }
  where mseg.bwart = '101'
```

### Pattern 4: BPMN Best Practices Template

```xml
<!-- Well-structured BPMN process -->
<bpmn:process id="P2P_Standard" name="Procure-to-Pay Standard" isExecutable="true">
  <!-- Single start event -->
  <bpmn:startEvent id="Start" name="Purchase Need Identified"/>

  <!-- Clear task naming: Verb + Object -->
  <bpmn:userTask id="T1" name="Create Purchase Requisition"/>
  <bpmn:userTask id="T2" name="Approve Purchase Requisition"/>

  <!-- Gateway with labeled outgoing flows -->
  <bpmn:exclusiveGateway id="G1" name="Approval Decision"/>
  <bpmn:sequenceFlow id="F_Approved" name="Approved" sourceRef="G1" targetRef="T3"/>
  <bpmn:sequenceFlow id="F_Rejected" name="Rejected" sourceRef="G1" targetRef="T_Reject"/>

  <bpmn:serviceTask id="T3" name="Create Purchase Order"/>
  <bpmn:userTask id="T4" name="Confirm Goods Receipt"/>
  <bpmn:serviceTask id="T5" name="Process Invoice"/>
  <bpmn:serviceTask id="T6" name="Execute Payment"/>

  <bpmn:endEvent id="End_Success" name="Payment Completed"/>
  <bpmn:endEvent id="End_Rejected" name="Requisition Rejected"/>
</bpmn:process>
```

### Pattern 5: Process KPI Configuration

```json
{
  "kpis": [
    {
      "name": "Cycle Time",
      "description": "Average time from requisition to payment",
      "formula": "AVG(EndTimestamp - StartTimestamp)",
      "target": "< 15 days",
      "dimension": "days"
    },
    {
      "name": "First-Time-Right Rate",
      "description": "Percentage of cases without rework loops",
      "formula": "COUNT(cases_no_rework) / COUNT(all_cases) * 100",
      "target": "> 85%",
      "dimension": "percentage"
    },
    {
      "name": "Automation Rate",
      "description": "Activities executed by system vs. total",
      "formula": "COUNT(system_activities) / COUNT(all_activities) * 100",
      "target": "> 60%",
      "dimension": "percentage"
    },
    {
      "name": "Maverick Buying Rate",
      "description": "POs created without prior requisition",
      "formula": "COUNT(po_without_pr) / COUNT(all_po) * 100",
      "target": "< 5%",
      "dimension": "percentage"
    }
  ]
}
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `401` | Session expired | Token timeout (default 30 min) | Re-authenticate; implement token refresh |
| `403` | Access denied | Missing workspace permissions | Check Signavio role assignments |
| `404` | Model not found | Wrong revision ID or deleted model | Use directory API to get current revision |
| `409` | Conflict | Concurrent model edit | Reload model, merge changes manually |
| Mining: No data | Empty process graph | Event log has no matching cases | Verify CaseID linking across activities |
| Mining: Spaghetti | Too many variants | Missing activity normalization | Standardize activity names; filter outliers |
| Export: Timeout | Large model export failed | Model too complex (>200 elements) | Split into subprocesses; export parts |
| Import: Invalid BPMN | Schema validation error | Non-standard BPMN extensions | Remove vendor-specific extensions before import |

## Performance Tips

1. **Event log size** — Keep under 10M events per analysis; sample or partition by date range
2. **Activity normalization** — Standardize naming before import; "Create PO" and "PO Creation" = same activity
3. **Case linking** — Use document flow tables (VBFA, EKBE) to link cross-module cases
4. **Incremental mining** — Schedule delta extracts (changed since last run) for ongoing monitoring
5. **Model complexity** — Keep BPMN models under 50 elements per diagram; use subprocesses for detail
6. **Variant analysis** — Focus on top 20 variants (usually 80%+ of cases); group rare variants as "Other"
7. **Collaboration Hub** — Publish only approved models; use governance workflow for version control

## Gotchas

- **Signavio vs. BPA**: Signavio models are *design-time* reference; SAP Build Process Automation is *runtime* execution — they complement, not replace each other
- **BPMN compliance**: Signavio enforces strict BPMN 2.0; models from other tools may need cleanup before import
- **Event timestamp granularity**: Second-level timestamps required for accurate mining; day-level creates artificial parallelism
- **Process Intelligence licensing**: Mining capabilities require separate PI license; Process Manager alone doesn't include mining
- **S/4HANA connector**: Pre-built extractors exist for O2C, P2P, AP — custom processes need manual event log setup
