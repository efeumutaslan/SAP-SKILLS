# Decision Table Design Patterns

## Overview

Decisions in SAP Build Process Automation evaluate business rules using decision tables
(if/then format) or text rules (natural language). They can be deployed independently
and called via RESTful Decision API.

## Decision Table Structure

```
┌─────────────────────────────────────────────────────────────┐
│ Decision Table: Determine Approval Level                     │
├──────────────┬────────────┬──────────────┬──────────────────┤
│ IF           │ IF         │ THEN         │ THEN             │
│ OrderAmount  │ Region     │ ApprovalLevel│ ApprovalLimit    │
├──────────────┼────────────┼──────────────┼──────────────────┤
│ > 50000      │ ANY        │ VP           │ 100000           │
│ > 10000      │ EMEA       │ Director     │ 50000            │
│ > 10000      │ APAC       │ Director     │ 50000            │
│ > 5000       │ ANY        │ Manager      │ 10000            │
│ <= 5000      │ ANY        │ TeamLead     │ 5000             │
│ DEFAULT      │ DEFAULT    │ Manager      │ 10000            │
├──────────────┴────────────┴──────────────┴──────────────────┤
│ Hit Policy: First Match (top-down, stops at first hit)      │
└─────────────────────────────────────────────────────────────┘
```

## Execution Modes

### First Match
- Evaluates rules top-to-bottom
- Returns the FIRST matching rule
- Order matters — put most specific rules at the top
- Always add a DEFAULT/catch-all rule at the bottom

### All Match
- Evaluates ALL rules
- Returns every matching rule
- Use for: accumulating results, multiple approvers, combined conditions

## Pattern 1: Approval Routing

**Use case:** Route approval to the correct person based on amount and department.

| IF Amount | IF Department | THEN Approver | THEN SLA (hours) |
|-----------|--------------|---------------|-------------------|
| > 100000 | ANY | CFO | 48 |
| > 50000 | Finance | Finance Director | 24 |
| > 50000 | Operations | Operations VP | 24 |
| > 10000 | ANY | Department Manager | 16 |
| > 1000 | ANY | Team Lead | 8 |
| <= 1000 | ANY | Auto-Approve | 0 |

**Hit Policy:** First Match

## Pattern 2: Risk Classification

**Use case:** Classify vendor risk level for compliance.

| IF Country | IF Annual Revenue | IF Years Active | THEN Risk Level | THEN Review Frequency |
|-----------|------------------|----------------|----------------|----------------------|
| Sanctioned List | ANY | ANY | Critical | Quarterly |
| ANY | < 100000 | < 2 | High | Semi-Annual |
| ANY | < 100000 | >= 2 | Medium | Annual |
| ANY | >= 100000 | < 2 | Medium | Annual |
| ANY | >= 100000 | >= 2 | Low | Biennial |

**Hit Policy:** First Match

## Pattern 3: Pricing / Discount Calculation

**Use case:** Calculate discount based on customer tier and order volume.

| IF Customer Tier | IF Order Quantity | THEN Discount % | THEN Free Shipping |
|-----------------|------------------|-----------------|-------------------|
| Platinum | >= 100 | 20 | Yes |
| Platinum | >= 50 | 15 | Yes |
| Platinum | < 50 | 10 | Yes |
| Gold | >= 100 | 15 | Yes |
| Gold | >= 50 | 10 | No |
| Gold | < 50 | 5 | No |
| Silver | >= 100 | 10 | No |
| Silver | < 100 | 3 | No |
| Standard | ANY | 0 | No |

**Hit Policy:** First Match

## Pattern 4: Multi-Approver Chain (All Match)

**Use case:** Determine ALL required approvers for a purchase request.

| IF Amount | IF Category | THEN Approver Role | THEN Required |
|-----------|-----------|-------------------|---------------|
| > 0 | ANY | Line Manager | Yes |
| > 5000 | ANY | Department Head | Yes |
| > 5000 | IT Equipment | IT Manager | Yes |
| > 5000 | Software | Software Compliance | Yes |
| > 25000 | ANY | Finance Controller | Yes |
| > 100000 | ANY | Board Member | Yes |

**Hit Policy:** All Match — Returns ALL matching rows (e.g., a $30,000 IT purchase
triggers Line Manager + Department Head + IT Manager + Finance Controller)

## Pattern 5: SLA Determination

**Use case:** Set response SLA based on ticket priority and customer type.

| IF Priority | IF Customer Type | THEN Response (hours) | THEN Resolution (hours) |
|------------|-----------------|----------------------|------------------------|
| Critical | Enterprise | 1 | 4 |
| Critical | Standard | 2 | 8 |
| High | Enterprise | 4 | 16 |
| High | Standard | 8 | 24 |
| Medium | Enterprise | 8 | 48 |
| Medium | Standard | 16 | 72 |
| Low | ANY | 24 | 120 |

## Text Rules (Alternative to Tables)

For complex logic that doesn't fit tabular format:

```
IF OrderAmount > 50000 AND Region = "EMEA" AND IsNewCustomer = true
  THEN SET ApprovalLevel = "Director"
       AND SET RequiresCredit = true
       AND SET CreditCheckType = "Full"

ELSEIF OrderAmount > 50000 AND IsNewCustomer = false
  THEN SET ApprovalLevel = "Manager"
       AND SET RequiresCredit = false

ELSE
  SET ApprovalLevel = "TeamLead"
  SET RequiresCredit = false
```

## Independent Decision Deployment

Decisions can be deployed and called independently via REST API:

```http
POST /v1/rule-services
Content-Type: application/json
Authorization: Bearer <token>

{
  "RuleServiceId": "<decision_id>",
  "Vocabulary": [
    {
      "OrderRequest": {
        "OrderAmount": 15000,
        "Region": "EMEA",
        "Department": "Finance"
      }
    }
  ]
}

Response:
{
  "Result": [
    {
      "ApprovalResult": {
        "ApprovalLevel": "Director",
        "SLA": 24,
        "ApprovalLimit": 50000
      }
    }
  ]
}
```

## Best Practices

1. **Always add a DEFAULT rule** — prevents empty results
2. **Order matters in First Match** — most specific rules first, general last
3. **Use meaningful column names** — they become API field names
4. **Test edge cases** — boundary values (exactly 10000, empty fields, nulls)
5. **Document business rules** — add descriptions to each decision
6. **Version independently** — decisions change more often than workflows
7. **Use data types consistently** — number vs string can cause silent mismatches
8. **Consider managed decisions** — let business users update rules without redeployment
