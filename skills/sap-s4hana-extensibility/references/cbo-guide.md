# Custom Business Objects (CBO) — Complete Guide

## Overview

Custom Business Objects replace traditional Z-tables in the cloud-first paradigm.
Created via the **Custom Business Objects** Fiori app without ABAP development.

## When to Use CBO vs. RAP BO

| Criteria | CBO (Key-User) | RAP BO (Developer) |
|----------|---------------|-------------------|
| Complexity | Simple master/transactional data | Complex business logic |
| Creator | Consultant / Key User | ABAP Developer |
| Tool | Fiori app (no ADT needed) | ADT (Eclipse) |
| Logic | Limited (published BAdIs only) | Full ABAP Cloud |
| API | Auto-generated OData | Custom OData (full control) |
| UI | Auto-generated Fiori app | Custom Fiori Elements or freestyle |
| Hierarchy | Up to 5 levels | Unlimited |
| Best for | Reference data, simple tracking | Core business processes |

## Creation Step-by-Step

### Step 1: Open Custom Business Objects App
- Fiori Launchpad → **Custom Business Objects** (or search in app finder)
- Click **New** to create a new CBO

### Step 2: Define the Business Object
```
Name:         YY1_ProjectTracker
Label:        Project Tracker
Description:  Track project milestones and status
```

### Step 3: Define Fields (Root Node)

| Field Name | Type | Length | Key | Notes |
|-----------|------|--------|-----|-------|
| ProjectID | Numeric Text | 10 | Yes | Auto-generated key |
| ProjectName | Text | 100 | No | |
| Description | Text | 255 | No | |
| Status | Code List | - | No | Link to YY1_ProjectStatus code list |
| Priority | Code List | - | No | Link to YY1_Priority code list |
| StartDate | Date | - | No | |
| EndDate | Date | - | No | |
| Budget | Amount | 15.2 | No | |
| Currency | Currency | 5 | No | |
| ResponsiblePerson | Text | 40 | No | |
| CompanyCode | Text | 4 | No | |

### Step 4: Add Child Node (Item Level)

Click **New Node** on the root:
```
Node Name:    Milestone
Label:        Project Milestone
```

| Field Name | Type | Length | Key | Notes |
|-----------|------|--------|-----|-------|
| MilestoneID | Numeric Text | 5 | Yes | Within project |
| MilestoneName | Text | 100 | No | |
| PlannedDate | Date | - | No | |
| ActualDate | Date | - | No | |
| MilestoneStatus | Code List | - | No | |
| CompletionPct | Numeric | 3 | No | 0-100 |

### Step 5: Create Code Lists

Code lists are separate CBOs with type "Code List":

**YY1_ProjectStatus:**
| Code | Description |
|------|-------------|
| PLAN | Planning |
| ACTV | Active |
| HOLD | On Hold |
| COMP | Completed |
| CNCL | Cancelled |

**YY1_Priority:**
| Code | Description |
|------|-------------|
| H | High |
| M | Medium |
| L | Low |

### Step 6: Enable UI Generation
- Check the **UI Generation** checkbox
- System auto-generates a Fiori maintenance app (SM30 equivalent)
- The app appears in the Fiori Launchpad after publishing

### Step 7: Add Business Logic

**After Modification — Determination (auto-calculations):**
```abap
" Set default values on create
IF projecttracker-status IS INITIAL.
  projecttracker-status = 'PLAN'.
ENDIF.
IF projecttracker-startdate IS INITIAL.
  projecttracker-startdate = cl_abap_context_info=>get_system_date( ).
ENDIF.
```

**Before Save — Validation (mandatory checks):**
```abap
" Validate end date is after start date
IF projecttracker-enddate IS NOT INITIAL
   AND projecttracker-enddate < projecttracker-startdate.
  APPEND VALUE #(
    %msg = new_message(
      id       = 'ZCBO'
      number   = '001'
      severity = if_abap_behv_message=>severity-error )
  ) TO reported-projecttracker.
ENDIF.

" Validate project name is not empty
IF projecttracker-projectname IS INITIAL.
  APPEND VALUE #(
    %msg = new_message_with_text(
      severity = if_abap_behv_message=>severity-error
      text     = 'Project name is mandatory' )
  ) TO reported-projecttracker.
ENDIF.
```

### Step 8: Publish
- Click **Publish** to activate the CBO
- System generates: database table, CDS view, OData service, Fiori app (if enabled)

## Auto-Generated Artifacts

After publishing, the system creates:

| Artifact | Naming Pattern | Example |
|----------|---------------|---------|
| Database table | `YY1_<NAME>` | `YY1_PROJECTTRACKER` |
| CDS view | `YY1_<NAME>` | `YY1_PROJECTTRACKER` |
| OData service | `YY1_<NAME>_CDS` | `YY1_PROJECTTRACKER_CDS` |
| Service URL | `/sap/opu/odata/sap/YY1_<NAME>_CDS/` | |
| Fiori app | Auto-generated maintenance UI | |

## OData API Usage

The auto-generated OData service supports standard CRUD operations:

```http
# Read all projects
GET /sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/YY1_PROJECTTRACKER

# Read single project with milestones
GET /sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/YY1_PROJECTTRACKER('0000000001')?$expand=to_Milestone

# Create project
POST /sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/YY1_PROJECTTRACKER
Content-Type: application/json
{
  "ProjectName": "New Project",
  "Status": "PLAN",
  "Priority": "H",
  "StartDate": "/Date(1711929600000)/",
  "Budget": "50000.00",
  "Currency": "EUR"
}

# Update project
PATCH /sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/YY1_PROJECTTRACKER('0000000001')
Content-Type: application/json
{ "Status": "ACTV" }

# Delete project
DELETE /sap/opu/odata/sap/YY1_PROJECTTRACKER_CDS/YY1_PROJECTTRACKER('0000000001')
```

## Integration Patterns

### 1. Expose CBO API for Side-by-Side Apps
- CBO OData service is automatically available for BTP apps via destination
- Configure Communication Scenario + Communication Arrangement

### 2. Reference in Custom Fields
- CBOs can be referenced as value help sources from Custom Fields on standard objects
- Example: Custom field "Project Reference" on Sales Order → value help from CBO

### 3. Use in Analytical Queries
- Create custom analytical queries on CBO data via **Custom Analytical Queries** app
- Combine CBO data with standard SAP data in reports

### 4. Extend with SAP Build Apps
- For richer UI beyond auto-generated maintenance app
- Connect Build Apps to CBO OData service

## Platform Differences

| Feature | Public Cloud | Private Cloud | On-Premise |
|---------|-------------|---------------|------------|
| CBO creation | Yes | Yes | Yes |
| UI generation | Yes | Yes | **No** (must build UI separately) |
| Code lists | Yes | Yes | Yes |
| Multi-level (5) | Yes | Yes | Yes |
| Business logic | Yes (published BAdIs) | Yes | Limited |
| OData API | Yes | Yes | Yes |

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|---------|
| "Maximum fields exceeded" | Per-node field limit reached | Split data into parent/child nodes |
| "Association target not published" | Target CBO/code list not published | Publish target first, then create association |
| "Transport failed" | CBO not in transport request | Use Extensibility Inventory to assign transport |
| UI generation not available | On-premise system | Build maintenance UI manually (Fiori Elements) |
| OData returns empty | CBO published but no data | Verify publishing was successful; check authorization |
| Code list values not showing | Code list CBO not published | Publish the code list CBO separately |

## Lifecycle Management

### Export/Import (Transport)
1. Open **Extensibility Inventory** Fiori app
2. Find the CBO and its dependent objects
3. Assign to a transport request
4. Release and import to target system

### Version Control
- CBOs don't have built-in versioning
- Track changes via Extensibility Inventory (shows who changed what, when)
- Export CBO definition for documentation purposes
