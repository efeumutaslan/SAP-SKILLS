---
name: sap-build-process-automation
description: >
  SAP Build Process Automation skill for workflow, RPA, and business rules development.
  Use when creating approval workflows, decision tables, RPA bots (Desktop Agent), API
  triggers, or event-driven processes from S/4HANA. Also covers Forms, Actions (OData/REST
  connectors), Visibility dashboards, and process monitoring. If the user mentions SBPA,
  SAP workflow, approval process, decision table, or RPA bot on BTP, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP Build Process Automation

## Related Skills
- `sap-s4hana-extensibility` — S/4HANA event sources and API integration
- `sap-security-authorization` — BTP authorization for process automation
- `sap-rap-comprehensive` — RAP business events as process triggers
- `sap-event-mesh` — Event-driven triggers from S/4HANA business events
- `sap-signavio` — Model processes in Signavio, automate in SBPA
- `sap-integration-suite-advanced` — Complex API connectors for Actions

## Quick Start

**Create a workflow in 5 steps:**
1. SAP Build Lobby → Create → Business Process Project
2. Add a Process → Choose trigger: Form, API, or Event
3. Add steps: Approval → Decision → Action → (repeat)
4. Configure conditions (If/Else gateways)
5. Release → Deploy → Test in Monitor tab

**Architecture:**
```
SAP Build Process Automation (BTP)
├── Process Builder    — Visual workflow modeling
├── Decision Editor    — Business rules / decision tables
├── Automation Editor  — RPA bot designer
├── Form Builder       — Trigger, approval, task forms
├── Visibility         — Process monitoring dashboards
└── Actions            — API connectors (OData, REST)
```

## Core Concepts

### Trigger Types

| Trigger | Start Method | Use Case |
|---------|-------------|----------|
| **Form** | User fills a request form | Leave request, purchase approval |
| **API** | REST API call (OAuth2) | System integration, external apps |
| **Event** | Event Mesh subscription | S/4HANA business events, SuccessFactors events |

### Step Types

| Step | Description |
|------|-------------|
| **Approval** | Routes to approver(s) with approve/reject form |
| **Decision** | Evaluates business rules (decision table or text rule) |
| **Automation** | Runs RPA bot (attended or unattended) |
| **Action** | Calls external API (OData/REST) |
| **Sub-Process** | Reusable embedded process |
| **Mail** | Sends notification email |
| **Condition** | If/Else routing based on data |

### Decision Tables

Decision tables are if/then rule engines:

```
IF OrderAmount > 10000 AND Region = "EMEA"
THEN ApprovalLevel = "Director", Priority = "High"

IF OrderAmount > 5000 AND Region = "EMEA"
THEN ApprovalLevel = "Manager", Priority = "Medium"

IF OrderAmount <= 5000
THEN ApprovalLevel = "TeamLead", Priority = "Low"
```

**Execution modes:**
- **First Match** — Returns the first matching rule (top-down, stops at first hit)
- **All Match** — Returns all matching rules

Decisions can be deployed independently and called via RESTful Decision API.

### Form Types

| Type | Purpose | Editable |
|------|---------|----------|
| **Trigger Form** | Starts the process (user input) | Yes — full input |
| **Approval Form** | Shows context + approve/reject | Read-only context + action buttons |
| **Task Form** | Additional user input mid-process | Yes — partial input |
| **Notification Form** | Information display only | Read-only |

## Common Patterns

### Pattern 1: Purchase Order Approval Workflow

```
[Form Trigger: PO Request]
    → [Decision: Approval Level]
        IF amount > 10000 → [Approval: Director]
        IF amount > 5000  → [Approval: Manager]
        ELSE              → [Auto-Approve]
    → [Action: Create PO in S/4HANA via OData]
    → [Mail: Notify Requester]
```

### Pattern 2: API Trigger Setup

1. Add API trigger to process
2. Note the generated API endpoint and definition ID
3. Configure OAuth2 credentials in BTP service key
4. Call endpoint:
```json
POST /workflow/rest/v1/workflow-instances
Headers: Authorization: Bearer <token>
Body: {
  "definitionId": "{{process_definition_id}}",
  "context": {
    "orderId": "PO-12345",
    "amount": 15000,
    "requester": "john.doe@company.com"
  }
}
```

### Pattern 3: Event Trigger from S/4HANA

1. Configure SAP Event Mesh on BTP
2. In S/4HANA: Enable business events (e.g., `sap.s4.beh.purchaseorder.v1.PurchaseOrder.Created.v1`)
3. In SBPA: Add Event Trigger → select event from catalog
4. Map event payload to process context variables
5. Process starts automatically when event fires

### Pattern 4: Action (API Connector)

1. Create Action Project in SAP Build
2. Import API specification (OData metadata or OpenAPI)
3. Configure destination:
```json
{
  "Name": "S4HANA_API",
  "Type": "HTTP",
  "URL": "https://my-s4.ondemand.com",
  "Authentication": "OAuth2ClientCredentials",
  "ProxyType": "Internet",
  "sap.processautomation.enabled": true,
  "sap.applicationdevelopment.actions.enabled": true
}
```
4. Use Action step in process to call the API

### Pattern 5: RPA Automation

```
Automation: Extract Invoice Data
1. Open Browser → Navigate to vendor portal
2. Read Table → Extract invoice line items
3. Loop → For each line item:
   a. Map fields to S/4HANA format
   b. Call Action: Post invoice via API
4. Log results → Send summary email
```

**Desktop Agent requirements:** Windows only, installed locally, connects to BTP tenant.

## Error Catalog

| Error | Cause | Fix |
|-------|-------|-----|
| 403 Forbidden on deploy | Missing role collection `ProcessAutomationAdmin` | Assign role collection in BTP cockpit |
| "Process stuck in running" | Approval task not assigned or recipient offline | Check Monitor → open instance → reassign task |
| Action timeout | API destination unreachable or slow | Check destination config; increase timeout |
| Automation "Agent Offline" | Desktop Agent not running or disconnected | Start Desktop Agent; check network connectivity |
| Event trigger not firing | Event Mesh subscription misconfigured | Verify topic subscription and event format |
| Decision returns empty | No matching rule found | Add a default/catch-all rule at bottom of decision table |
| Form data not passing | Variable binding missing between steps | Check input/output mapping in process flow |
| "503 Action Internal Error" | Destination missing required properties | Add `sap.processautomation.enabled = true` to destination |
| Deploy fails "version exists" | Same version already deployed | Increment version number before release |
| Memory exceeded in automation | Processing large dataset in single loop | Use batch processing (chunks of 100-500 records) |

## Performance Tips

- Use **sub-processes** for reusable logic (DRY principle)
- Define **custom variables** as constants for magic values
- **Batch processing** in automations: process records in chunks, not one-by-one
- Use **destination variables** for multi-environment support (dev/test/prod)
- Deploy decisions independently when business rules change frequently
- Keep forms simple: <15 fields per form for good UX
- Use **SemVer** (x.y.z) versioning for release management

## Bundled Resources

| File | When to Read |
|------|-------------|
| `references/sbpa-complete-guide.md` | Full SBPA reference with all component details |
| `references/decision-patterns.md` | Decision table design patterns and examples |
| `references/action-connector-guide.md` | Setting up API connectors with destinations |
| `templates/approval-workflow.json` | Basic approval workflow template |
| `templates/decision-table.json` | Decision table configuration template |

## Gotchas

- **Process vs. Automation**: "Process" = workflow (server-side); "Automation" = RPA bot (desktop agent, client-side) — they're complementary but very different
- **Desktop Agent requirement**: RPA automations require SAP Build Desktop Agent installed on user's Windows machine — cannot run headless on server
- **Decision table versioning**: Published decision tables are immutable; to change, create a new version and update the process to reference it
- **Form data types**: SBPA forms support limited data types; complex nested structures may need flattening before passing to forms
- **API trigger authentication**: API triggers use OAuth 2.0 from BTP — the calling system needs a proper service key, not basic auth
- **Error handling scope**: Try-catch in processes catches only the enclosed steps; unhandled errors in subprocesses bubble up to parent
- **Parallel branches and merge**: Parallel gateways must have matching merge gateway — orphaned branches cause process to hang indefinitely
- **SAP Build Store content**: Pre-built content from SAP Build Store may need customization; don't assume it works out-of-the-box for your scenario

## Advanced Patterns

### Pattern 6: Multi-Level Approval with Escalation

```
[Form: Expense Report]
    → [Decision: Approval Matrix]
        IF amount > 50000 → [Approval: CFO] (deadline: 3 days)
        IF amount > 10000 → [Approval: Director] (deadline: 2 days)
        IF amount > 1000  → [Approval: Manager] (deadline: 1 day)
        ELSE              → [Auto-Approve]
    → [Condition: Approved?]
        YES → [Action: Post to S/4HANA FI]
              → [Mail: Confirmation to requester]
        NO  → [Mail: Rejection with reason]
              → [End]

Escalation: If no response within deadline →
    → [Action: Notify substitute approver]
    → [Approval: Substitute] (deadline: 1 day)
    → [Condition: Still no response?] → [Auto-Reject]
```

### Pattern 7: Parallel Processing with Aggregation

```
[API Trigger: Multi-Department Review]
    → [Parallel Gateway]
        ├── [Approval: Legal Review]
        ├── [Approval: Finance Review]
        └── [Approval: Compliance Review]
    → [Merge Gateway: All must approve]
    → [Decision: Final Assessment]
    → [Action: Update status in S/4HANA]
```

### Pattern 8: Exception Handling

```json
{
  "errorHandling": {
    "type": "boundary-event",
    "attachedTo": "Action: Create PO",
    "errorType": "timeout",
    "handler": [
      { "step": "Log error to monitoring" },
      { "step": "Retry with exponential backoff", "maxRetries": 3 },
      { "step": "If still failing: route to manual queue" }
    ]
  }
}
```

## Source Documentation

- [SAP Build Process Automation Documentation](https://help.sap.com/docs/build-process-automation)
- [SAP Build Store](https://store.build.cloud.sap/)
- [SAP Tutorials: Build Process Automation](https://developers.sap.com/tutorial-navigator.html?tag=software-product%3Atechnology-platform%2Fsap-build%2Fsap-build-process-automation)
- [GitHub: SAP-samples SBPA](https://github.com/SAP-samples/process-automation-content)
