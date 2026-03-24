---
name: sap-cloud-alm
description: >
  SAP Cloud ALM (Application Lifecycle Management) skill. Use when configuring health
  monitoring, real user monitoring (RUM), integration/job monitoring, or managing SAP
  implementations (change/test/deployment management). If the user mentions Cloud ALM,
  SAP monitoring, RUM, health check, or ALM operations, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Cloud ALM — Application Lifecycle Management

## Related Skills
- `sap-testing-quality` — Test execution integrates with Cloud ALM Test Management
- `sap-devops-cicd` — CI/CD pipelines integrate with Cloud ALM Deployment Management
- `sap-signavio` — Process models from Signavio link to Cloud ALM implementation

## Quick Start

**Two main modes:**

| Mode | Purpose | Key Features |
|------|---------|-------------|
| **Cloud ALM for Implementation** | Project delivery | Tasks, Requirements, Test Management, Deployment |
| **Cloud ALM for Operations** | Run & monitor | Health Monitoring, Integration Monitoring, RUM, BPM |

**Access:** SAP Cloud ALM is provisioned via SAP for Me → Cloud ALM tenant (included with SAP Enterprise Support)

**First API call — List Projects:**

```bash
curl -X GET "https://{{CALM_HOST}}/api/calm-projects/v1/projects" \
  -H "Authorization: Bearer {{TOKEN}}" \
  -H "Accept: application/json"
```

## Core Concepts

### Implementation Capabilities
| Capability | Purpose | Integration |
|-----------|---------|-------------|
| **Project & Task Management** | Plan sprints, assign work | Jira sync (optional) |
| **Requirements Management** | Capture & trace requirements | Link to test cases |
| **Process Management** | Define scope, map processes | Signavio import |
| **Test Management** | Manual & automated test execution | ATC, Tricentis |
| **Deployment Management** | Track transports & deployments | CTS+, gCTS, BTP deploy |
| **Change Management** | Change requests & approvals | ChaRM-like workflow |

### Operations Capabilities
| Capability | Monitored Systems | Key Metrics |
|-----------|-------------------|-------------|
| **Health Monitoring** | S/4HANA, BTP, SuccessFactors | System availability, DB, memory |
| **Integration Monitoring** | Integration Suite, PI/PO | Message throughput, errors |
| **Real User Monitoring (RUM)** | Fiori apps, Web apps | Page load time, JS errors |
| **Job Monitoring** | Background jobs, BTP jobs | Success/failure, duration |
| **Business Process Monitoring** | End-to-end processes | SLA compliance, throughput |
| **Configuration Monitoring** | System configuration | Drift detection, compliance |

### Managed System Registration
```
SAP Cloud ALM ◄──── Service Key ────► Managed System
    │                                    │
    │  HTTPS (pull metrics)              │ Push events
    │  ← Health data                     │
    │  ← Alert notifications             │
    └────────────────────────────────────┘
```

**Registration steps:**
1. BTP cockpit → Service Marketplace → `sap-cloud-alm` service
2. Create service key with managed system credentials
3. Cloud ALM → Landscape Management → Add managed system
4. Enter service key details → Test connection → Activate

## Common Patterns

### Pattern 1: Health Monitoring Setup

**Configure custom health metric:**

```json
// Custom metric definition
{
  "metricId": "custom_order_backlog",
  "name": "Order Processing Backlog",
  "description": "Number of unprocessed sales orders",
  "category": "Business",
  "unit": "count",
  "thresholds": {
    "warning": 100,
    "critical": 500
  },
  "collection": {
    "type": "odata",
    "url": "/sap/opu/odata/sap/API_SALES_ORDER_SRV/A_SalesOrder/$count?$filter=OverallSDProcessStatus eq 'A'",
    "interval": 300
  }
}
```

### Pattern 2: Business Process Monitoring — O2C

```json
{
  "processId": "O2C_Standard",
  "name": "Order-to-Cash Standard",
  "steps": [
    {
      "stepId": "SO_CREATE",
      "name": "Sales Order Created",
      "source": "S/4HANA",
      "event": "SalesOrder.Created",
      "sla": {"maxDuration": "PT4H"}
    },
    {
      "stepId": "DELIVERY",
      "name": "Delivery Created",
      "source": "S/4HANA",
      "event": "OutboundDelivery.Created",
      "sla": {"maxDuration": "PT24H", "from": "SO_CREATE"}
    },
    {
      "stepId": "BILLING",
      "name": "Billing Document Created",
      "source": "S/4HANA",
      "event": "BillingDocument.Created",
      "sla": {"maxDuration": "PT48H", "from": "DELIVERY"}
    },
    {
      "stepId": "PAYMENT",
      "name": "Payment Received",
      "source": "S/4HANA",
      "event": "CustomerPayment.Cleared",
      "sla": {"maxDuration": "P30D", "from": "BILLING"}
    }
  ],
  "alerts": {
    "slaBreachChannel": "email",
    "recipients": ["process-owner@example.com"]
  }
}
```

### Pattern 3: Cloud ALM API — Create Task

```python
import requests

def create_task(calm_host, token, project_id, task_data):
    """Create implementation task in Cloud ALM."""
    resp = requests.post(
        f"https://{calm_host}/api/calm-tasks/v1/tasks",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json={
            "projectId": project_id,
            "title": task_data["title"],
            "description": task_data["description"],
            "type": task_data.get("type", "IMPLEMENTATION"),
            "status": "OPEN",
            "priority": task_data.get("priority", "MEDIUM"),
            "assignee": task_data.get("assignee"),
            "dueDate": task_data.get("due_date"),
            "tags": task_data.get("tags", [])
        }
    )
    resp.raise_for_status()
    return resp.json()
```

### Pattern 4: Test Management Integration

```python
def create_test_case(calm_host, token, project_id, test_data):
    """Create manual test case linked to requirement."""
    resp = requests.post(
        f"https://{calm_host}/api/calm-testmanagement/v1/testcases",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json={
            "projectId": project_id,
            "title": test_data["title"],
            "requirementId": test_data.get("requirement_id"),
            "steps": [
                {
                    "stepNumber": i + 1,
                    "action": step["action"],
                    "expectedResult": step["expected"]
                }
                for i, step in enumerate(test_data["steps"])
            ],
            "priority": "HIGH",
            "automationStatus": "MANUAL"
        }
    )
    resp.raise_for_status()
    return resp.json()

def report_test_result(calm_host, token, test_case_id, result):
    """Report test execution result."""
    resp = requests.post(
        f"https://{calm_host}/api/calm-testmanagement/v1/testcases/{test_case_id}/executions",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        json={
            "status": result["status"],  # PASSED, FAILED, BLOCKED
            "executedBy": result["tester"],
            "executedOn": result["date"],
            "comment": result.get("comment", "")
        }
    )
    resp.raise_for_status()
    return resp.json()
```

### Pattern 5: Alert Notification Configuration

```json
{
  "alertRule": {
    "name": "Critical System Health",
    "scope": {
      "systems": ["S4H-PRD", "BTP-PRD"],
      "metrics": ["availability", "response_time", "error_rate"]
    },
    "conditions": {
      "severity": ["CRITICAL"],
      "duration": "PT5M"
    },
    "actions": [
      {
        "type": "EMAIL",
        "recipients": ["basis-team@example.com"],
        "template": "system_critical_alert"
      },
      {
        "type": "WEBHOOK",
        "url": "https://hooks.slack.com/services/{{WEBHOOK_ID}}",
        "payload": {
          "text": "🚨 {{alertName}}: {{systemName}} - {{metricName}} is {{severity}}"
        }
      }
    ]
  }
}
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `401` | Unauthorized | Token expired or wrong tenant | Refresh OAuth token; check CALM URL |
| `403` | Insufficient scope | Missing Cloud ALM role | Assign role in SAP Cloud Identity Services |
| `404` | Project not found | Wrong project ID or no access | Verify project ID; check project membership |
| Connection failed | Managed system unreachable | Network/firewall issue | Check connectivity; verify service key |
| No health data | Metrics not collected | System not registered or agent missing | Re-register managed system; check agent status |
| RUM: No data | No user sessions captured | RUM script not injected | Add RUM JavaScript snippet to Fiori launchpad |
| Alert storm | Too many alerts | Thresholds too sensitive | Adjust thresholds; add suppression rules |
| Sync error | Jira/external sync failed | API key expired or endpoint changed | Update integration credentials |

## Performance Tips

1. **Selective monitoring** — Don't monitor everything; focus on business-critical systems and processes
2. **Threshold tuning** — Start with vendor defaults, adjust after 2-4 weeks of baseline data
3. **Alert grouping** — Group related alerts to prevent alert fatigue; use correlation rules
4. **RUM sampling** — For high-traffic apps, sample RUM data (10-25%) instead of collecting all sessions
5. **API pagination** — Cloud ALM APIs return max 100 items; always implement cursor-based pagination
6. **Dashboard design** — Create role-specific dashboards (Basis, Developers, Business) not one-size-fits-all
7. **Data retention** — Configure metric retention periods; 90 days for detailed, 1 year for aggregated

## Gotchas

- **Licensing**: Cloud ALM is free with SAP Enterprise Support, but some advanced features need additional license
- **Tenant isolation**: Cloud ALM has its own BTP subaccount; don't mix with application subaccounts
- **Time zones**: All Cloud ALM timestamps are UTC; dashboard display uses browser timezone
- **Managed system limit**: Check your entitlement for max number of managed systems
- **RUM privacy**: Real User Monitoring collects user session data — ensure GDPR/privacy compliance
- **API versioning**: Cloud ALM APIs are versioned (`/v1/`); always specify version in requests
