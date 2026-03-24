# SAP RAP (RESTful Application Programming Model) - Complete Developer Reference

> Research compiled: 2026-03-23
> Covers: SAP BTP ABAP Environment, S/4HANA Cloud, S/4HANA On-Premise

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [CDS View Entity Modeling](#2-cds-view-entity-modeling)
3. [Behavior Definition (BDEF)](#3-behavior-definition-bdef)
4. [Managed vs Unmanaged vs Managed-with-Unmanaged-Save](#4-implementation-types)
5. [Behavior Definition Syntax Deep Dive](#5-behavior-definition-syntax-deep-dive)
6. [Draft Handling](#6-draft-handling)
7. [Authorization Control](#7-authorization-control)
8. [Entity Manipulation Language (EML)](#8-entity-manipulation-language-eml)
9. [Numbering (Early, Late, Managed)](#9-numbering)
10. [Feature Control](#10-feature-control)
11. [Business Events](#11-business-events)
12. [Virtual Elements](#12-virtual-elements)
13. [Test Doubles (CL_BOTD)](#13-test-doubles-cl_botd)
14. [Service Definition and Binding](#14-service-definition-and-binding)
15. [Projection Layer](#15-projection-layer)
16. [BTP vs S/4HANA Differences](#16-btp-vs-s4hana-differences)
17. [Common Errors and Troubleshooting](#17-common-errors-and-troubleshooting)
18. [Best Practices](#18-best-practices)

---

## 1. Architecture Overview

RAP is the ABAP development model for building cloud-ready, clean-core-compliant business apps, services, and extensions. It runs on SAP BTP ABAP Environment, S/4HANA Cloud, and S/4HANA On-Premise.

### Three-Layer Architecture

```
┌─────────────────────────────────────────────┐
│  SERVICE LAYER                               │
│  ├── Service Binding (OData V2/V4, InA)     │
│  └── Service Definition (exposes entities)   │
├─────────────────────────────────────────────┤
│  BUSINESS OBJECT LAYER                       │
│  ├── Projection BDEF (behavior projection)   │
│  ├── Projection CDS Views (consumption)      │
│  ├── Metadata Extensions (UI annotations)    │
│  ├── Interface BDEF (behavior definition)    │
│  ├── Behavior Implementation (ABAP classes)  │
│  └── Interface CDS Views (BO data model)     │
├─────────────────────────────────────────────┤
│  DATA LAYER                                  │
│  ├── Database Tables                         │
│  ├── Draft Tables (if draft-enabled)         │
│  └── Number Range Objects                    │
└─────────────────────────────────────────────┘
```

### Key Development Artifacts

| Artifact | Purpose | Created In |
|---|---|---|
| CDS View Entity (Interface) | Data model / BO structure | DDL Source |
| CDS Projection View | Consumption-specific view | DDL Source |
| Metadata Extension | UI annotations (separated) | DDL Source |
| Behavior Definition (Interface) | BO transactional behavior | BDEF |
| Behavior Projection | Expose subset of behavior | BDEF |
| Behavior Implementation | ABAP handler/saver classes | ABAP Class |
| Service Definition | Which entities to expose | SRVD |
| Service Binding | Protocol binding (OData V2/V4) | SRVB |

### RAP Interaction Flow

```
Client Request (Fiori / API)
    ↓
Service Binding (OData protocol)
    ↓
Service Definition (entity exposure)
    ↓
Projection Layer (CDS projection + BDEF projection)
    ↓
Interface Layer (CDS interface view + BDEF interface)
    ↓
Behavior Implementation (handler class: FOR MODIFY, FOR READ)
    ↓
Transactional Buffer (managed by framework or developer)
    ↓
Save Sequence → Database
```

---

## 2. CDS View Entity Modeling

### Root Entity

The root entity is the top-level node representing the entire Business Object. Every BO has exactly one root node.

```cds
define root view entity ZI_Travel
  as select from ztravel
  composition [0..*] of ZI_Booking as _Booking
  association [0..1] to ZI_Agency   as _Agency   on $projection.AgencyID = _Agency.AgencyID
  association [0..1] to ZI_Customer as _Customer on $projection.CustomerID = _Customer.CustomerID
{
  key travel_id       as TravelID,
      agency_id       as AgencyID,
      customer_id     as CustomerID,
      begin_date      as BeginDate,
      end_date        as EndDate,
      booking_fee     as BookingFee,
      total_price     as TotalPrice,
      currency_code   as CurrencyCode,
      overall_status  as OverallStatus,
      description     as Description,
      @Semantics.systemDateTime.createdAt: true
      created_at      as CreatedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      /* Associations */
      _Booking,
      _Agency,
      _Customer
}
```

### Child Entity (with composition to parent)

```cds
define view entity ZI_Booking
  as select from zbooking
  association to parent ZI_Travel as _Travel
    on $projection.TravelID = _Travel.TravelID
  composition [0..*] of ZI_BookingSupplement as _BookingSupplement
{
  key travel_id       as TravelID,
  key booking_id      as BookingID,
      booking_date    as BookingDate,
      customer_id     as CustomerID,
      carrier_id      as CarrierID,
      connection_id   as ConnectionID,
      flight_date     as FlightDate,
      flight_price    as FlightPrice,
      currency_code   as CurrencyCode,
      booking_status  as BookingStatus,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Travel,
      _BookingSupplement
}
```

### Grandchild Entity

```cds
define view entity ZI_BookingSupplement
  as select from zbooksuppl
  association to parent ZI_Booking as _Booking
    on  $projection.TravelID  = _Booking.TravelID
    and $projection.BookingID = _Booking.BookingID
{
  key travel_id       as TravelID,
  key booking_id      as BookingID,
  key booking_supplement_id as BookingSupplementID,
      supplement_id   as SupplementID,
      price           as Price,
      currency_code   as CurrencyCode,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      _Booking
}
```

### Composition vs Association

| Aspect | Composition | Association |
|---|---|---|
| Relationship | Parent-child (ownership) | Loose reference |
| ON Condition | Derived from `to parent` in child | Explicitly defined |
| Delete Behavior | Child deleted with parent | Child survives parent deletion |
| Transaction Boundary | Same LUW | Independent |
| Syntax (parent) | `composition [0..*] of ChildEntity` | `association [0..1] to Entity` |
| Syntax (child) | `association to parent ParentEntity` | `association [0..1] to Entity` |

### Key Rules for Composition Trees

1. Every BO has exactly ONE root entity
2. Compositions define parent-child ownership relationships
3. Child entities MUST have `association to parent` back to parent
4. No ON condition needed on the composition itself (derived from child's to-parent association)
5. Composition cardinality: `[0..*]` or `[1..*]` (parent to children)
6. The to-parent association always has cardinality `[1..1]` (implicitly)

### CDS Projection Views

```cds
define root view entity ZC_Travel
  provider contract transactional_query
  as projection on ZI_Travel
{
  key TravelID,
      AgencyID,
      CustomerID,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      OverallStatus,
      Description,
      CreatedAt,
      LastChangedAt,
      LocalLastChangedAt,

      /* Redirected composition */
      _Booking : redirected to composition child ZC_Booking,
      _Agency,
      _Customer
}
```

Child projection:
```cds
define view entity ZC_Booking
  as projection on ZI_Booking
{
  key TravelID,
  key BookingID,
      BookingDate,
      CustomerID,
      CarrierID,
      ConnectionID,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LocalLastChangedAt,

      _Travel : redirected to parent ZC_Travel,
      _BookingSupplement : redirected to composition child ZC_BookingSupplement
}
```

### Projection Redirections

- `redirected to composition child` - for compositions going DOWN the tree
- `redirected to parent` - for to-parent associations going UP the tree
- `redirected to` - for general association redirections

### Metadata Extensions (UI Annotations)

```cds
@Metadata.layer: #CORE
annotate entity ZC_Travel with
{
  @UI.facet: [
    { id: 'Travel',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'Travel',
      position: 10 },
    { id: 'Booking',
      purpose: #STANDARD,
      type: #LINEITEM_REFERENCE,
      label: 'Bookings',
      position: 20,
      targetElement: '_Booking' }
  ]

  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  @UI.selectionField: [{ position: 10 }]
  TravelID;

  @UI.lineItem: [{ position: 20, importance: #HIGH }]
  @UI.identification: [{ position: 20 }]
  @UI.selectionField: [{ position: 20 }]
  AgencyID;

  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  OverallStatus;
}
```

Metadata extension layers (lowest to highest priority):
- `#CORE`
- `#LOCALIZATION`
- `#INDUSTRY`
- `#PARTNER`
- `#CUSTOMER`

---

## 3. Behavior Definition (BDEF)

### Interface Behavior Definition Structure

```
managed [implementation in class ZBP_I_TRAVEL unique];
strict ( 2 );
with draft;

define behavior for ZI_Travel alias Travel
persistent table ztravel
draft table zd_travel
etag master LocalLastChangedAt
total etag LastChangedAt
lock master
authorization master ( global, instance )
{
  // Standard operations
  create;
  update;
  delete;

  // Draft actions
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare
  {
    validation validateCustomer;
    validation validateDates;
    determination calculateTotalPrice;
  }

  // Fields
  field ( readonly ) TravelID, CreatedAt, LastChangedAt, LocalLastChangedAt;
  field ( readonly : update ) AgencyID;
  field ( mandatory ) CustomerID, BeginDate, EndDate;
  field ( features : instance ) OverallStatus;
  field ( numbering : managed ) TravelID;

  // Validations
  validation validateCustomer on save { create; field CustomerID; }
  validation validateDates on save { create; field BeginDate, EndDate; }
  validation validateStatus on save { field OverallStatus; }

  // Determinations
  determination setStatusOpen on modify { create; }
  determination calculateTotalPrice on modify { field BookingFee; }

  // Actions
  action ( features : instance ) acceptTravel result [1] $self;
  action ( features : instance ) rejectTravel result [1] $self;
  static action createFromTemplate parameter ZA_TravelParam result [1] $self;
  factory action copyTravel [1];

  // Side Effects
  side effects
  {
    field BookingFee affects field TotalPrice;
    field CurrencyCode affects field TotalPrice;
    determine action Prepare executed on field BookingFee affects messages;
  }

  // Associations
  association _Booking { create; with draft; }

  // Mapping
  mapping for ztravel corresponding
  {
    TravelID = travel_id;
    AgencyID = agency_id;
    CustomerID = customer_id;
    BeginDate = begin_date;
    EndDate = end_date;
    BookingFee = booking_fee;
    TotalPrice = total_price;
    CurrencyCode = currency_code;
    OverallStatus = overall_status;
    Description = description;
    CreatedAt = created_at;
    LastChangedAt = last_changed_at;
    LocalLastChangedAt = local_last_changed_at;
  }
}

define behavior for ZI_Booking alias Booking
persistent table zbooking
draft table zd_booking
etag master LocalLastChangedAt
lock dependent by _Travel
authorization dependent by _Travel
{
  update;
  delete;

  field ( readonly ) TravelID, BookingID;
  field ( numbering : managed ) BookingID;

  determination calculateFlightPrice on modify { field CarrierID, ConnectionID, FlightDate; }

  association _Travel { with draft; }
  association _BookingSupplement { create; with draft; }

  mapping for zbooking corresponding
  {
    TravelID = travel_id;
    BookingID = booking_id;
    BookingDate = booking_date;
    CustomerID = customer_id;
    CarrierID = carrier_id;
    ConnectionID = connection_id;
    FlightDate = flight_date;
    FlightPrice = flight_price;
    CurrencyCode = currency_code;
    BookingStatus = booking_status;
    LocalLastChangedAt = local_last_changed_at;
  }
}
```

---

## 4. Implementation Types

### Managed

```
managed implementation in class ZBP_I_TRAVEL unique;
```

- Framework provides the transactional buffer
- Standard CRUD operations work out of the box
- Developer only needs to implement non-standard logic (validations, determinations, actions)
- Framework handles save to database automatically
- Best for greenfield development

**When to use:** New applications, clean data model, no legacy persistence logic.

### Unmanaged

```
unmanaged implementation in class ZBP_I_TRAVEL unique;
```

- Developer provides EVERYTHING: transactional buffer + all operations + save handling
- All CRUD operations must be explicitly implemented
- Developer implements handler methods (FOR MODIFY, FOR READ, FOR LOCK)
- Developer implements saver methods (SAVE_MODIFIED, CLEANUP, etc.)

**When to use:** Wrapping legacy code, complex custom persistence, non-standard data sources.

### Managed with Unmanaged Save

```
managed implementation in class ZBP_I_TRAVEL unique;
with unmanaged save;
```

- Framework manages the transactional buffer and CRUD operations
- Developer implements only the SAVE_MODIFIED method for custom persistence
- Combines managed convenience with custom save logic
- No need to implement handler methods for CRUD

**When to use:** Clean transactional model but need to write to legacy tables, custom tables, or call BAPIs/FMs during save.

### Managed with Additional Save

```
managed implementation in class ZBP_I_TRAVEL unique;
with additional save;
```

- Framework does the standard managed save AND also calls your SAVE_MODIFIED
- Useful when you need side effects during save (e.g., log entries, notifications)
- The standard save still happens normally

**When to use:** Standard persistence plus additional side effects during save.

### Comparison Matrix

| Feature | Managed | Unmanaged | Managed + Unmanaged Save | Managed + Additional Save |
|---|---|---|---|---|
| Transactional Buffer | Framework | Developer | Framework | Framework |
| CRUD Implementation | Framework | Developer | Framework | Framework |
| Save to DB | Framework | Developer | Developer | Framework + Developer |
| Validations | Developer | Developer | Developer | Developer |
| Determinations | Developer | Developer | Developer | Developer |
| Actions | Developer | Developer | Developer | Developer |
| Numbering | Managed/Early/Late | Early/Late | Managed/Early/Late | Managed/Early/Late |

---

## 5. Behavior Definition Syntax Deep Dive

### Header Options

```
managed implementation in class ZBP_I_TRAVEL unique;
strict ( 2 );              " Strict mode (1 or 2). Mode 2 required for side effects
with draft;                 " Enables draft handling for entire BO
```

### Strict Mode

- `strict ( 1 )`: Basic upgrade safety checks
- `strict ( 2 )`: Enhanced checks, REQUIRED for side effects. Best practice to always use `strict ( 2 )`

### Standard Operations

```
create;                                        " Enable create
create ( precheck );                           " Create with precheck
update;                                        " Enable update
update ( precheck );                           " Update with precheck
delete;                                        " Enable delete
delete ( precheck );                           " Delete with precheck
```

### Field Characteristics

```
field ( readonly )           FieldA, FieldB;              " Always read-only
field ( readonly : update )  FieldC;                       " Read-only on update, editable on create
field ( mandatory )          FieldD, FieldE;              " Mandatory (UI enforcement)
field ( features : instance ) FieldF;                      " Dynamic feature control
field ( numbering : managed ) KeyField;                    " Framework-managed numbering
field ( notrigger )          FieldG;                       " Cannot be used as trigger condition
field ( suppress )           InternalField;                " Suppressed, not exposed
```

### Validations

```
" Triggered on save, by create operation
validation validateCustomer on save { create; field CustomerID; }

" Triggered on save, by specific fields
validation validateDates on save { field BeginDate, EndDate; }

" Triggered on save, by create and update
validation validateStatus on save { create; update; }
```

**Important:** Validations always run during the save sequence. The trigger conditions determine WHEN the validation is relevant, not when it executes.

### Prechecks vs Validations

| Aspect | Precheck | Validation |
|---|---|---|
| When executed | Before data enters transactional buffer | During save sequence |
| Purpose | Reject invalid requests early | Business logic consistency check |
| Buffer state | Data NOT yet in buffer | Data IS in buffer |
| Declaration | `create ( precheck );` | `validation X on save { ... }` |
| Implementation | `FOR PRECHECK` method | `FOR VALIDATE` method |
| Use case | Deny create when preconditions fail | Validate field combinations |

### Determinations

```
" On modify - executes immediately when trigger condition is met
determination setStatusOpen on modify { create; }
determination calculatePrice on modify { field BookingFee, CurrencyCode; }

" On save - executes during save sequence
determination calculateTravelID on save { create; }
determination setDefaultDates on save { create; }
```

**Determination Trigger Best Practice:** Do NOT combine CRUD operations (create, update) with field triggers. Specify ONLY field triggers to avoid redundant executions:
```
" BAD - triggers on every create AND every field change
determination calcPrice on modify { create; update; field BookingFee; }

" GOOD - triggers only when BookingFee changes
determination calcPrice on modify { field BookingFee; }
```

**Execution Order:** Determinations execute FIRST, then validations.

### Actions

```
" Instance action (operates on a specific instance)
action acceptTravel result [1] $self;

" Instance action with parameter
action rateTravel parameter ZA_Rating result [1] $self;

" Instance action with feature control
action ( features : instance ) acceptTravel result [1] $self;

" Static action (not bound to any instance)
static action createDefault result [1] $self;

" Static action with parameter
static action createFromTemplate parameter ZA_TravelParam result [1] $self;

" Factory action (creates a new instance, instance-bound)
factory action copyTravel [1];

" Static factory action (creates a new instance, not instance-bound)
static factory action createFromDefault [1];

" Static default factory action (replaces standard create on UI)
static default factory action createFromDefault [1];

" Internal action (only callable from within BO, not exposed via OData)
internal action recalculate;

" Deep action (OData V4 only - complex parameters)
action submitWithDetails deep parameter ZA_DeepParam result [1] $self;

" Action with multiple result instances
action splitTravel result [0..*] $self;
```

### Determine Actions

```
" Allow consumer to trigger determinations/validations on demand
draft determine action Prepare
{
  validation validateCustomer;
  validation validateDates;
  determination calculateTotalPrice;
}
```

### Side Effects

Only available with `strict ( 2 )`.

```
side effects
{
  " Field affects other field
  field BookingFee affects field TotalPrice;

  " Field affects field in related entity
  field FlightPrice affects field _Travel.TotalPrice;

  " Action affects field
  action acceptTravel affects field OverallStatus;

  " Determine action triggered by field, affects messages
  determine action Prepare executed on field BookingFee affects messages;

  " Field affects entire entity (re-read)
  field OverallStatus affects entity _Travel;

  " Field affects permissions
  field OverallStatus affects permissions;
}
```

### Concurrency Control

```
" Optimistic concurrency (ETag)
etag master LocalLastChangedAt           " Entity maintains own ETag
etag dependent by _Travel                 " Uses parent's ETag

" Total ETag (mandatory for draft BOs)
total etag LastChangedAt

" Pessimistic concurrency (Lock)
lock master                               " Entity controls its own lock
lock master unmanaged                     " Developer implements lock
lock dependent by _Travel                 " Uses parent's lock
```

### Mapping

```
mapping for ztravel corresponding
{
  TravelID = travel_id;
  AgencyID = agency_id;
}

" For control structure mapping
mapping for ztravel control corresponding
{
  TravelID = travel_id;
  AgencyID = agency_id;
}
```

### Augmentation (Projection Layer)

```
" In projection BDEF - augment operations
augment { ... }

" Augmentation adds data to incoming requests BEFORE they reach the base BO
" CANNOT overwrite fields already set by the consumer
```

---

## 6. Draft Handling

### Enabling Draft

1. Add `with draft;` to the BDEF header
2. Define draft tables for each entity in the composition tree
3. Add draft actions in the BDEF
4. Add `with draft;` to association declarations

### BDEF Draft Configuration

```
managed implementation in class ZBP_I_TRAVEL unique;
strict ( 2 );
with draft;

define behavior for ZI_Travel alias Travel
persistent table ztravel
draft table zd_travel                    " <<< Draft table declaration
lock master total etag LastChangedAt
...
{
  draft action Edit;
  draft action Activate optimized;       " 'optimized' skips unchanged data
  draft action Discard;
  draft action Resume;
  draft determine action Prepare { ... }

  association _Booking { create; with draft; }  " <<< with draft on association
}
```

### Draft Table Structure

Draft tables must include:
- All fields from the persistent table
- Additional draft administrative fields (added automatically by framework):
  - `%is_draft` (key field)
  - `%draft_uuid`
  - `%draft_owner`
  - `%draft_created_at`
  - `%draft_last_changed_at`
  - etc.

### Draft Actions Explained

| Action | Purpose | Triggered By |
|---|---|---|
| `Edit` | Creates draft instance from active instance | User clicks Edit |
| `Activate` | Saves draft to active data (triggers save sequence) | User clicks Save |
| `Discard` | Deletes draft instance | User clicks Cancel/Discard |
| `Resume` | Resumes editing existing draft | User reopens draft |
| `Prepare` | Triggers specified validations/determinations on draft | Before Activate, or on demand |

### Draft Lifecycle

```
Active Instance → [Edit] → Draft Instance
Draft Instance → [Modify] → Updated Draft
Draft Instance → [Prepare] → Validated Draft
Draft Instance → [Activate] → Active Instance (save sequence)
Draft Instance → [Discard] → Deleted Draft
No Instance → [Create] → New Draft Instance
```

### Key Draft Behaviors

- When a draft is created from an active instance, the active instance is exclusively locked
- Only ONE user can have an active draft for a given instance
- Draft instances are stored in the draft table, separate from active data
- The `%is_draft` field distinguishes draft ('01') from active ('00') instances
- `Activate optimized` only processes entities that actually changed (performance)
- `Prepare` is typically called before `Activate` to run validations

### ETag with Draft

- `total etag` is mandatory for draft-enabled BOs
- When using OData V2 with draft, you may need to disable ETag handling in the projection behavior definition

---

## 7. Authorization Control

### BDEF Declaration

```
" Root entity: master with both global and instance checks
authorization master ( global, instance )

" Root entity: master with only instance check
authorization master ( instance )

" Root entity: master with only global check
authorization master ( global )

" Child entity: dependent on parent
authorization dependent by _Travel
```

### Global Authorization

Checks whether a user can perform an operation AT ALL (not instance-specific).

```abap
METHOD get_global_authorizations.
  " Check if user has create authorization
  IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
    AUTHORITY-CHECK OBJECT 'ZOBJTRAVEL'
      ID 'ACTVT' FIELD '01'.
    IF sy-subrc = 0.
      result-%create = if_abap_behv=>auth-allowed.
    ELSE.
      result-%create = if_abap_behv=>auth-unauthorized.
    ENDIF.
  ENDIF.

  " Check update authorization
  IF requested_authorizations-%update EQ if_abap_behv=>mk-on.
    AUTHORITY-CHECK OBJECT 'ZOBJTRAVEL'
      ID 'ACTVT' FIELD '02'.
    result-%update = COND #(
      WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).
  ENDIF.

  " Check delete authorization
  IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.
    AUTHORITY-CHECK OBJECT 'ZOBJTRAVEL'
      ID 'ACTVT' FIELD '06'.
    result-%delete = COND #(
      WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).
  ENDIF.
ENDMETHOD.
```

### Instance Authorization

Checks authorization for a specific instance (e.g., user can only edit their own travel).

```abap
METHOD get_instance_authorizations.
  " Read relevant instance data
  READ ENTITIES OF ZI_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( AgencyID )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel)
    FAILED failed.

  LOOP AT lt_travel INTO DATA(ls_travel).
    " Check instance-level authorization
    AUTHORITY-CHECK OBJECT 'ZOBJTRAVEL'
      ID 'ACTVT' FIELD '02'
      ID 'ZAGENCY' FIELD ls_travel-AgencyID.

    DATA(lv_auth) = COND #(
      WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
      ELSE if_abap_behv=>auth-unauthorized ).

    APPEND VALUE #(
      %tky = ls_travel-%tky
      %update = lv_auth
      %delete = lv_auth
      %action-acceptTravel = lv_auth
    ) TO result.
  ENDLOOP.
ENDMETHOD.
```

### Authorization for Read Operations

Read authorization is NOT handled in the BDEF. It is handled via CDS access control (DCL):

```cds
@EndUserText.label: 'Access Control for Travel'
@MappingRole: true
define role ZI_Travel {
  grant select on ZI_Travel
  where ( AgencyID ) = aspect pfcg_auth ( ZOBJTRAVEL, ZAGENCY, ACTVT = '03' );
}
```

### Combined Global + Instance

When both are defined, the framework:
1. First checks global authorization
2. Then checks instance authorization for instance-based operations
3. Both must return `authorized` for the operation to proceed

---

## 8. Entity Manipulation Language (EML)

EML is the ABAP language subset for accessing RAP business object data programmatically.

### READ ENTITIES

```abap
" Read specific fields
READ ENTITIES OF ZI_Travel
  ENTITY Travel
  FIELDS ( TravelID AgencyID CustomerID TotalPrice OverallStatus )
  WITH VALUE #( ( %tky = <fs_travel>-%tky ) )
  RESULT DATA(lt_travel)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

" Read all fields
READ ENTITIES OF ZI_Travel
  ENTITY Travel
  ALL FIELDS
  WITH VALUE #( ( TravelID = '00000001' ) )
  RESULT DATA(lt_travel_all)
  FAILED DATA(ls_failed2)
  REPORTED DATA(ls_reported2).

" Read by association
READ ENTITIES OF ZI_Travel
  ENTITY Travel BY \_Booking
  ALL FIELDS
  WITH VALUE #( ( TravelID = '00000001' ) )
  RESULT DATA(lt_bookings)
  LINK DATA(lt_link)
  FAILED DATA(ls_failed3)
  REPORTED DATA(ls_reported3).

" Read in local mode (bypasses authorization, feature control)
READ ENTITIES OF ZI_Travel IN LOCAL MODE
  ENTITY Travel
  ALL FIELDS
  WITH VALUE #( ( %tky = <fs_travel>-%tky ) )
  RESULT DATA(lt_travel_local).
```

### MODIFY ENTITIES

```abap
" CREATE
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate Description )
  WITH VALUE #( (
    %cid      = 'CID_001'
    AgencyID  = '000001'
    CustomerID = '000001'
    BeginDate = cl_abap_context_info=>get_system_date( )
    EndDate   = cl_abap_context_info=>get_system_date( ) + 10
    Description = 'Test Travel'
  ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).

" UPDATE
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  UPDATE FIELDS ( OverallStatus )
  WITH VALUE #( (
    %tky = <fs_travel>-%tky
    OverallStatus = 'A'    " Accepted
  ) )
  FAILED DATA(ls_failed_upd)
  REPORTED DATA(ls_reported_upd).

" DELETE
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  DELETE FROM VALUE #( (
    %tky = <fs_travel>-%tky
  ) )
  FAILED DATA(ls_failed_del)
  REPORTED DATA(ls_reported_del).

" EXECUTE ACTION
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  EXECUTE acceptTravel FROM VALUE #( (
    %tky = <fs_travel>-%tky
  ) )
  RESULT DATA(lt_accept_result)
  FAILED DATA(ls_failed_act)
  REPORTED DATA(ls_reported_act).

" CREATE BY ASSOCIATION (create child from parent)
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  CREATE BY \_Booking
  FIELDS ( BookingDate CustomerID CarrierID ConnectionID FlightDate )
  WITH VALUE #( (
    %tky = <fs_travel>-%tky
    %target = VALUE #( (
      %cid       = 'BCID_001'
      BookingDate = cl_abap_context_info=>get_system_date( )
      CustomerID  = '000001'
      CarrierID   = 'AA'
      ConnectionID = '0017'
      FlightDate   = cl_abap_context_info=>get_system_date( ) + 5
    ) )
  ) )
  MAPPED DATA(ls_mapped_book)
  FAILED DATA(ls_failed_book)
  REPORTED DATA(ls_reported_book).
```

### COMMIT ENTITIES

```abap
" Trigger save sequence
COMMIT ENTITIES.

" Check if commit was successful
IF sy-subrc <> 0.
  " Handle error
ENDIF.

" With response parameters
COMMIT ENTITIES
  RESPONSE OF ZI_Travel
  FAILED DATA(ls_commit_failed)
  REPORTED DATA(ls_commit_reported).
```

### Key EML Concepts

| Concept | Description |
|---|---|
| `%cid` | Content ID for newly created instances (temporary ID before save) |
| `%tky` | Transactional key (includes `%is_draft` for draft BOs) |
| `%key` | Primary key fields |
| `%pid` | Preliminary ID (used in late numbering) |
| `%control` | Control structure indicating which fields are provided |
| `%param` | Action parameters |
| `IN LOCAL MODE` | Bypasses authorization checks, feature control, and precheck |
| `MAPPED` | Returns mapping of %cid to actual keys |
| `FAILED` | Returns information about failed instances |
| `REPORTED` | Returns messages |

### EML Inside Behavior Implementation

Within handler methods, use shorthand syntax:

```abap
" Inside a handler method (FOR MODIFY)
READ ENTITIES OF ZI_Travel IN LOCAL MODE
  ENTITY Travel
  ALL FIELDS WITH CORRESPONDING #( keys )
  RESULT DATA(lt_travel).

MODIFY ENTITIES OF ZI_Travel IN LOCAL MODE
  ENTITY Travel
  UPDATE FIELDS ( TotalPrice )
  WITH VALUE #( FOR travel IN lt_travel (
    %tky = travel-%tky
    TotalPrice = travel-BookingFee + lv_flight_total
  ) )
  REPORTED DATA(ls_reported).
```

---

## 9. Numbering

### Types Overview

| Type | When Assigned | Who Assigns | Key in Buffer | Use Case |
|---|---|---|---|---|
| External | Before CREATE | Consumer | Final key | Consumer-provided IDs |
| Managed (Early) | During CREATE | Framework | Final key | UUID-based keys |
| Unmanaged (Early) | During CREATE | Developer | Final key | Number ranges, custom logic |
| Late | During SAVE | Developer | Temporary → Final | Gap-free numbering |

### External Numbering (Default)

No special BDEF syntax. Consumer provides the key value.

### Managed Early Numbering

```
field ( numbering : managed ) TravelID;
```

- Framework generates the key (typically UUID-based)
- Key field should be of type `sysuuid_x16` or `sysuuid_c36`
- Key is available immediately in the transactional buffer

### Unmanaged Early Numbering

```
early numbering
```

Developer implements `FOR NUMBERING` method:

```abap
METHOD earlynumbering_create.
  " Get next number from number range
  DATA(lv_travel_id) = get_next_number( ).

  mapped-travel = VALUE #( FOR entity IN entities (
    %cid  = entity-%cid
    %key  = entity-%key
    TravelID = lv_travel_id
  ) ).
ENDMETHOD.
```

### Late Numbering

```
late numbering
```

- Key field MUST be `field ( readonly )` (user cannot enter it)
- Developer implements `adjust_numbers` in the saver class
- Numbers assigned just BEFORE data is written to DB (after point of no return)
- Enables gap-free numbering

```abap
METHOD adjust_numbers.
  " In saver class
  DATA(lv_number) = 1.

  LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<fs_travel>).
    " Assign the final number
    <fs_travel>-TravelID = lv_number.
    lv_number += 1.
  ENDLOOP.
ENDMETHOD.
```

### Late Numbering with %pid

When using late numbering, instances in the buffer use `%pid` (preliminary ID) until the final key is assigned:

```abap
" Consumer uses %pid to reference instances before save
MODIFY ENTITIES OF ZI_Travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID )
  WITH VALUE #( (
    %cid = 'CID_001'
    " No TravelID provided - will be assigned late
    AgencyID = '000001'
    CustomerID = '000001'
  ) )
  MAPPED DATA(ls_mapped).

" ls_mapped contains %pid for the new instance
```

---

## 10. Feature Control

### Static Feature Control

Defined in BDEF only. No implementation required.

```
" Field is always read-only
field ( readonly ) TravelID, CreatedAt, LastChangedAt;

" Field is mandatory
field ( mandatory ) CustomerID, BeginDate, EndDate;

" Field is read-only on update (editable on create only)
field ( readonly : update ) AgencyID;
```

### Dynamic (Instance) Feature Control

Defined in BDEF with implementation in handler class.

```
" In BDEF
field ( features : instance ) OverallStatus, BookingFee;
action ( features : instance ) acceptTravel;
action ( features : instance ) rejectTravel;
```

Implementation:

```abap
METHOD get_instance_features.
  " Read current state
  READ ENTITIES OF ZI_Travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( OverallStatus )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel)
    FAILED failed.

  result = VALUE #( FOR travel IN lt_travel (
    %tky = travel-%tky

    " If status is 'Accepted', disable accept action and make status read-only
    %field-OverallStatus = COND #(
      WHEN travel-OverallStatus = 'A'
      THEN if_abap_behv=>fc-f-read_only
      ELSE if_abap_behv=>fc-f-unrestricted )

    %field-BookingFee = COND #(
      WHEN travel-OverallStatus = 'A'
      THEN if_abap_behv=>fc-f-read_only
      ELSE if_abap_behv=>fc-f-unrestricted )

    %action-acceptTravel = COND #(
      WHEN travel-OverallStatus = 'A'
      THEN if_abap_behv=>fc-o-disabled
      ELSE if_abap_behv=>fc-o-enabled )

    %action-rejectTravel = COND #(
      WHEN travel-OverallStatus = 'X'
      THEN if_abap_behv=>fc-o-disabled
      ELSE if_abap_behv=>fc-o-enabled )
  ) ).
ENDMETHOD.
```

### Feature Control Constants

```abap
" For fields
if_abap_behv=>fc-f-unrestricted    " Editable
if_abap_behv=>fc-f-read_only       " Read-only
if_abap_behv=>fc-f-mandatory       " Mandatory
if_abap_behv=>fc-f-hidden          " Hidden (not shown on UI)

" For operations/actions
if_abap_behv=>fc-o-enabled         " Enabled
if_abap_behv=>fc-o-disabled        " Disabled (greyed out)
```

### Global Feature Control

Defined at the entity level for operations:

```
" In BDEF
create ( features : global );
update ( features : global );
delete ( features : global );
action ( features : global ) someAction;
```

Implementation via `get_global_features` method.

---

## 11. Business Events

### Defining Events in BDEF

```
define behavior for ZI_Travel alias Travel
...
{
  " Event without parameter
  event travelCreated;

  " Event with parameter (CDS abstract entity)
  event travelAccepted parameter ZA_TravelEvent;
}
```

### CDS Abstract Entity for Event Parameter

```cds
define abstract entity ZA_TravelEvent
{
  TravelID   : /dmo/travel_id;
  AgencyID   : /dmo/agency_id;
  CustomerID : /dmo/customer_id;
  Status     : /dmo/overall_status;
}
```

### Raising Events

Events can ONLY be raised in the saver class methods (save_modified, save):

```abap
METHOD save_modified.
  " After successful save, raise events
  IF create-travel IS NOT INITIAL.
    RAISE ENTITY EVENT ZI_Travel~travelCreated
      FROM VALUE #( FOR travel IN create-travel (
        TravelID = travel-TravelID
      ) ).
  ENDIF.

  " Event with parameter
  IF update-travel IS NOT INITIAL.
    RAISE ENTITY EVENT ZI_Travel~travelAccepted
      FROM VALUE #( FOR travel IN update-travel
        WHERE ( OverallStatus = 'A' ) (
        %key = VALUE #( TravelID = travel-TravelID )
        %param = VALUE #(
          TravelID   = travel-TravelID
          AgencyID   = travel-AgencyID
          CustomerID = travel-CustomerID
          Status     = travel-OverallStatus
        )
      ) ).
  ENDIF.
ENDMETHOD.
```

### Consuming Events Locally

```abap
CLASS zcl_travel_event_handler DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_event_handler.
ENDCLASS.

CLASS zcl_travel_event_handler IMPLEMENTATION.
  METHOD if_rap_event_handler~handle.
    " Event handler is processed ASYNCHRONOUSLY
    CASE event_id.
      WHEN 'TRAVELCREATED'.
        " Handle event
      WHEN 'TRAVELACCEPTED'.
        " Handle event with parameter
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
```

### Remote Event Consumption

On SAP BTP, events can be consumed via SAP Event Mesh for cross-system communication. On S/4HANA on-premise (2022+), events can also be raised and consumed.

---

## 12. Virtual Elements

### Definition in CDS Projection View

```cds
define root view entity ZC_Travel
  provider contract transactional_query
  as projection on ZI_Travel
{
  key TravelID,
      AgencyID,
      CustomerID,
      BeginDate,
      EndDate,
      TotalPrice,
      CurrencyCode,
      OverallStatus,

      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_TRAVEL_VE_CALC'
      cast( '' as abap.char(20) ) as DaysUntilDeparture,

      @ObjectModel.virtualElement: true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_TRAVEL_VE_CALC'
      cast( '' as abap.char(10) ) as StatusText,

      _Booking : redirected to composition child ZC_Booking
}
```

### Implementation Class

```abap
CLASS zcl_travel_ve_calc DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
ENDCLASS.

CLASS zcl_travel_ve_calc IMPLEMENTATION.
  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " Declare which original fields are needed for calculation
    IF line_exists( it_requested_calc_elements[ table_line = 'DAYSUNTILDEPARTURE' ] ).
      APPEND 'BEGINDATE' TO et_requested_orig_elements.
    ENDIF.
    IF line_exists( it_requested_calc_elements[ table_line = 'STATUSTEXT' ] ).
      APPEND 'OVERALLSTATUS' TO et_requested_orig_elements.
    ENDIF.
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA lt_calc TYPE STANDARD TABLE OF ZC_Travel WITH DEFAULT KEY.
    lt_calc = CORRESPONDING #( it_original_data ).

    LOOP AT lt_calc ASSIGNING FIELD-SYMBOL(<fs_calc>).
      DATA(ls_orig) = it_original_data[ sy-tabix ].

      " Calculate days until departure
      <fs_calc>-DaysUntilDeparture = |{ ls_orig-BeginDate - cl_abap_context_info=>get_system_date( ) } days|.

      " Map status to text
      <fs_calc>-StatusText = SWITCH #( ls_orig-OverallStatus
        WHEN 'O' THEN 'Open'
        WHEN 'A' THEN 'Accepted'
        WHEN 'X' THEN 'Rejected'
        ELSE 'Unknown' ).
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( lt_calc ).
  ENDMETHOD.
ENDCLASS.
```

### Key Constraints

- Virtual elements can ONLY be defined in projection views (not interface views)
- They are calculated on the ABAP application server (no HANA pushdown)
- They do NOT appear in Eclipse Data Preview (only via OData/SADL)
- Performance overhead: calculated for every read request
- Use sparingly for truly dynamic values that cannot be modeled in CDS

---

## 13. Test Doubles (CL_BOTD)

### Overview of RAP Testing Frameworks

| Framework | Class | Purpose |
|---|---|---|
| BO Test Double (Buffer) | `CL_BOTD_TXBUFDBL_BO_TEST_ENV` | Mock transactional buffer |
| BO Test Double (EML API) | `CL_BOTD_MOCKEMLAPI_BO_TEST_ENV` | Mock EML statements |
| CDS Test Double | `CL_CDS_TEST_ENVIRONMENT` | Mock CDS view data |
| OSQL Test Double | `CL_OSQL_TEST_ENVIRONMENT` | Mock database table data |

### Test Class Setup

```abap
CLASS ltc_travel DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA:
      cds_test_env TYPE REF TO if_cds_test_environment,
      sql_test_env TYPE REF TO if_osql_test_environment,
      environment  TYPE REF TO if_botd_txbufdbl_bo_test_env.

    CLASS-METHODS:
      class_setup,
      class_teardown.

    METHODS:
      setup,
      teardown,
      test_validate_customer FOR TESTING,
      test_set_status_open FOR TESTING,
      test_accept_travel FOR TESTING.
ENDCLASS.

CLASS ltc_travel IMPLEMENTATION.
  METHOD class_setup.
    " Create transactional buffer test double
    environment = cl_botd_txbufdbl_bo_test_env=>create(
      src_bindings = VALUE #( ( 'ZI_TRAVEL' ) )
    ).

    " Create CDS test environment
    cds_test_env = cl_cds_test_environment=>create(
      i_for_entity = 'ZI_TRAVEL'
    ).

    " Create SQL test environment (for direct table access)
    sql_test_env = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZTRAVEL' ) ( 'ZBOOKING' ) )
    ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
    cds_test_env->destroy( ).
    sql_test_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
    cds_test_env->clear_doubles( ).
    sql_test_env->clear_doubles( ).
  ENDMETHOD.

  METHOD teardown.
    " Clean up after each test
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD test_validate_customer.
    " Prepare test data
    DATA(lt_travel) = VALUE #( (
      TravelID   = '00000001'
      CustomerID = '000000'   " Invalid customer
    ) ).

    " Insert test data into buffer
    sql_test_env->insert_test_data( lt_travel ).

    " Execute validation
    " ...

    " Assert
    cl_abap_unit_assert=>assert_not_initial(
      act = ls_failed-travel
      msg = 'Validation should fail for invalid customer' ).
  ENDMETHOD.

  METHOD test_set_status_open.
    " Test determination sets status to 'O' on create
    MODIFY ENTITIES OF ZI_Travel
      ENTITY Travel
      CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate )
      WITH VALUE #( (
        %cid = 'CID_001'
        AgencyID = '000001'
        CustomerID = '000001'
        BeginDate = sy-datum
        EndDate = sy-datum + 10
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    " Read back to check determination result
    READ ENTITIES OF ZI_Travel
      ENTITY Travel
      FIELDS ( OverallStatus )
      WITH VALUE #( ( %cid_ref = 'CID_001' ) )
      RESULT DATA(lt_travel).

    cl_abap_unit_assert=>assert_equals(
      act = lt_travel[ 1 ]-OverallStatus
      exp = 'O'
      msg = 'Status should be Open after create' ).
  ENDMETHOD.

  METHOD test_accept_travel.
    " Setup: Create travel with status 'O'
    MODIFY ENTITIES OF ZI_Travel
      ENTITY Travel
      CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate OverallStatus )
      WITH VALUE #( (
        %cid = 'CID_001'
        AgencyID = '000001'
        CustomerID = '000001'
        BeginDate = sy-datum
        EndDate = sy-datum + 10
        OverallStatus = 'O'
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    " Execute action
    MODIFY ENTITIES OF ZI_Travel
      ENTITY Travel
      EXECUTE acceptTravel FROM VALUE #( (
        %cid_ref = 'CID_001'
      ) )
      RESULT DATA(lt_result)
      FAILED DATA(ls_failed_act)
      REPORTED DATA(ls_reported_act).

    cl_abap_unit_assert=>assert_equals(
      act = lt_result[ 1 ]-OverallStatus
      exp = 'A'
      msg = 'Status should be Accepted after action' ).
  ENDMETHOD.
ENDCLASS.
```

### Mock EML API Pattern

```abap
" For testing code that CALLS EML statements (external consumers)
DATA(mock_env) = cl_botd_mockemlapi_bo_test_env=>create(
  src_bindings = VALUE #( ( 'ZI_TRAVEL' ) )
).

" Configure mock responses
DATA(mock) = mock_env->get_mock( 'ZI_TRAVEL' ).
mock->when_read( )->then_return( VALUE #( ( TravelID = '00000001' ) ) ).
```

### Testing Best Practices

1. Always use `ROLLBACK ENTITIES` in teardown
2. Test each layer independently (CDS, behavior, service)
3. Use `CL_OSQL_TEST_ENVIRONMENT` for table data
4. Use `CL_CDS_TEST_ENVIRONMENT` for CDS view dependencies
5. Use `CL_BOTD_TXBUFDBL_BO_TEST_ENV` for testing behavior implementations
6. Test validations, determinations, and actions separately

---

## 14. Service Definition and Binding

### Service Definition

```cds
@EndUserText.label: 'Travel Service'
define service ZUI_TRAVEL {
  expose ZC_Travel as Travel;
  expose ZC_Booking as Booking;
  expose ZC_BookingSupplement as BookingSupplement;
  expose ZI_Agency as Agency;
  expose ZI_Customer as Customer;
  expose ZI_Carrier as Carrier;
}
```

### Service Binding Types

| Type | Protocol | Use Case |
|---|---|---|
| OData V2 - UI | OData V2 | SAP Fiori UI (legacy) |
| OData V2 - Web API | OData V2 | API consumption |
| OData V4 - UI | OData V4 | SAP Fiori UI (recommended for new) |
| OData V4 - Web API | OData V4 | API consumption |
| InA | InA protocol | SAP Analytics Cloud / HANA Enterprise Search |

### OData V2 vs V4 Key Differences

| Feature | OData V2 | OData V4 |
|---|---|---|
| Deep actions | Not supported | Supported |
| Value helps | Published automatically | Must be configured |
| Draft + ETag | May need disabling ETag | Full support |
| Deep table parameters | Not supported | Supported |
| Recommended for | Legacy apps | New development |

### Service Binding Creation (ADT)

1. Right-click service definition → New → Service Binding
2. Choose binding type (OData V2 UI, V4 UI, etc.)
3. Activate the service binding
4. Publish the service (click "Publish" in ADT)

---

## 15. Projection Layer

### Purpose

The projection layer adapts the BO interface for specific use cases/consumers. Multiple projections can exist for one BO.

### Architecture

```
                    ┌─── Projection A (Clerk App) ───── Service Def A ─── Binding A
BO Interface ───────┤
                    └─── Projection B (Admin App) ───── Service Def B ─── Binding B
```

### Projection CDS View

```cds
define root view entity ZC_Travel
  provider contract transactional_query       " Required for transactional projections
  as projection on ZI_Travel
{
  key TravelID,
      AgencyID,
      " Can omit fields not needed for this projection
      _Booking : redirected to composition child ZC_Booking
}
```

Provider contracts:
- `transactional_query` - For transactional (CRUD) scenarios
- `transactional_interface` - For API/integration scenarios
- `analytical_query` - For analytical scenarios

### Projection Behavior Definition

```
projection;
strict ( 2 );
use draft;

define behavior for ZC_Travel alias Travel
use etag
{
  use create;
  use update;
  use delete;

  use action acceptTravel;
  use action rejectTravel;
  " Omit actions not needed for this projection (e.g., no admin actions for clerk)

  use association _Booking { create; with draft; }
}

define behavior for ZC_Booking alias Booking
use etag
{
  use update;
  use delete;

  use association _Travel { with draft; }
  use association _BookingSupplement { create; with draft; }
}
```

### Key Points

- Projection BDEF uses `use` keyword (not `create`, `update`, `delete` directly)
- Only operations/actions listed with `use` are exposed
- Omitting an operation in projection effectively hides it for that use case
- `use draft;` in the projection header enables draft for this projection
- Projection can further restrict what the BO interface exposes

---

## 16. BTP vs S/4HANA Differences

### Platform Comparison

| Aspect | BTP ABAP Env | S/4HANA Cloud | S/4HANA On-Premise |
|---|---|---|---|
| ABAP Language | ABAP Cloud only | ABAP Cloud (ext.) | ABAP Cloud + Classic |
| Update Cycle | Quarterly | Bi-annual | Annual/Bi-annual |
| Released APIs | Allowlisted only | Allowlisted only | All (classic ABAP available) |
| Extensibility | Side-by-side | Key user + developer | All options |
| Custom Tables | ABAP Dictionary (cloud) | ABAP Dictionary (cloud) | ABAP Dictionary (full) |
| Transport | gCTS / ABAP Environment | CTS | CTS |
| RAP Feature Parity | Latest features first | Close behind BTP | Lags behind |

### Key Differences for RAP Development

**BTP ABAP Environment:**
- Must use released APIs only (no direct table access to SAP standard tables)
- No classic ABAP statements (no CALL FUNCTION, no WRITE, no ALV)
- gCTS for code transport
- SAP Event Mesh for remote event consumption
- Most frequent feature updates
- Higher licensing cost

**S/4HANA Cloud (Public/Private):**
- Embedded Steampunk for developer extensibility
- Key user extensibility for no-code changes
- Can use released SAP APIs
- Cannot modify SAP standard code

**S/4HANA On-Premise:**
- Full ABAP stack available (but ABAP Cloud is recommended for clean core)
- Can use classic ABAP alongside RAP
- Direct access to all database tables
- ABAP Cloud as opt-in for clean core readiness
- Feature set depends on release version (check SAP Note for feature availability)
- Can still use BAPIs, FMs alongside RAP

### ABAP Cloud Restrictions (BTP + Cloud)

- No `CALL FUNCTION` (use released wrappers)
- No `SELECT` from SAP standard tables (use released CDS views/APIs)
- No `AUTHORITY-CHECK` with custom objects unless released
- No classic dynpro/ALV
- Must use RAP for all transactional development

---

## 17. Common Errors and Troubleshooting

### Error: Messages Not Displaying on Fiori UI

**Problem:** Validation/determination messages don't show in Fiori Elements.

**Solution:**
1. Fill BOTH `failed` AND `reported` parameters
2. In `reported`, always fill `%tky` with the entity key
3. For draft BOs, set `%is_draft = if_abap_behv=>mk-on` (value '01') in the reported structure
4. For child entity validations, fill the `%path` with the parent relationship:
```abap
APPEND VALUE #(
  %tky = <booking>-%tky
  %path = VALUE #( travel-%tky = <travel>-%tky )
  %msg = new_message_with_text( text = 'Invalid booking' severity = if_abap_behv_message=>severity-error )
) TO reported-booking.
```

### Error: Determination Triggered Multiple Times

**Problem:** Determination fires more times than expected.

**Solution:** Don't combine CRUD operations with field triggers:
```
" BAD
determination calc on modify { create; update; field Price; }

" GOOD
determination calc on modify { field Price; }
```

### Error: Side Effects Not Working

**Problem:** Side effects don't trigger UI refresh.

**Solution:** Ensure `strict ( 2 )` is set in the BDEF header. Side effects only work with strict mode 2.

### Error: Draft - Exclusive Lock Timeout

**Problem:** User cannot edit because another user's draft lock is still active.

**Solution:** Locks have configurable timeouts. After the exclusive lock expires, an optimistic lock phase begins. Administrators can discard orphaned drafts.

### Error: Create by Association Fails

**Problem:** Creating a child entity via association returns errors.

**Solution:**
1. Ensure the association has `{ create; }` in the parent BDEF
2. For draft BOs, add `with draft;` to the association
3. Ensure child's `%cid` is set in the `%target` table
4. Check that key fields use correct numbering (managed/early/late)

### Error: EML Returns Empty Result

**Problem:** `READ ENTITIES` returns no data.

**Solution:**
1. Check that you're reading from the correct entity (interface vs projection)
2. Verify keys are correct (include `%is_draft` for draft instances)
3. If inside a handler method, use `IN LOCAL MODE` to bypass auth/feature control
4. Ensure the entity has data in the transactional buffer (or database for active instances)

### Error: Augmentation - Field Already Set

**Problem:** Augmentation fails with dump when trying to set a field.

**Solution:** Augmentation can ONLY set fields that are NOT already present in the incoming request. It cannot overwrite existing values.

### Error: Virtual Element Returns Empty

**Problem:** Virtual element shows empty in the UI.

**Solution:**
1. Virtual elements only work via OData/SADL (not Eclipse Data Preview)
2. Verify the implementing class name matches exactly (case-sensitive in annotation)
3. Check `get_calculation_info` method returns the required source fields
4. Ensure the virtual element is in the projection view (not the interface view)

### Debugging Tips

1. **ABAP Debugger:** Set breakpoints in handler/saver methods
2. **ABAP Cross Trace:** Enable in ADT for OData request/response tracing
3. **Gateway Error Log:** `/IWFND/ERROR_LOG` for OData V2 issues
4. **Service Binding Preview:** Test directly in ADT service binding preview
5. **EML Console:** Use `COMMIT ENTITIES` response to check for errors

---

## 18. Best Practices

### Data Model Design

1. Design the data model FIRST, before behavior
2. Use CDS view entities (not CDS views - the older syntax)
3. Keep the composition tree shallow (max 3-4 levels)
4. Use associations for loose references, compositions for owned children
5. Separate admin fields (created_by, changed_at) from business fields

### Behavior Definition

1. Always use `strict ( 2 )` for new development
2. Use managed scenario unless you have a strong reason not to
3. Keep validations focused: one validation per business rule
4. Prefer field triggers over CRUD triggers for determinations
5. Use `internal` keyword for actions that should not be exposed via OData
6. Use prechecks for early rejection of invalid requests
7. Use `IN LOCAL MODE` in handler methods to avoid circular authorization checks

### Draft Handling

1. Enable draft for all interactive (Fiori) applications
2. Use `Activate optimized` for performance
3. Use `Prepare` to run validations before activation
4. Always define `total etag` with draft

### Authorization

1. Use CDS access control (DCL) for read authorization
2. Use BDEF global authorization for operation-level checks
3. Use BDEF instance authorization for data-level checks
4. Combine global + instance for comprehensive coverage

### Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Interface CDS View (Root) | `ZI_<EntityName>` | `ZI_Travel` |
| Interface CDS View (Child) | `ZI_<ChildEntityName>` | `ZI_Booking` |
| Projection CDS View | `ZC_<EntityName>` | `ZC_Travel` |
| Behavior Implementation | `ZBP_I_<EntityName>` | `ZBP_I_Travel` |
| Draft Table | `ZD_<entity>` | `ZD_Travel` |
| Service Definition | `ZUI_<ServiceName>` | `ZUI_Travel` |
| Abstract Entity (Parameter) | `ZA_<ParamName>` | `ZA_TravelParam` |
| Metadata Extension | `ZC_<EntityName>` | (same as projection) |

### Performance

1. Minimize virtual elements (they bypass HANA pushdown)
2. Use `Activate optimized` for draft
3. Avoid reading all fields when only specific ones are needed
4. Use `%control` structure to update only changed fields
5. Be mindful of determination triggers (avoid unnecessary executions)

### Testing

1. Write unit tests for every validation, determination, and action
2. Use `CL_BOTD_TXBUFDBL_BO_TEST_ENV` for behavior testing
3. Use `CL_OSQL_TEST_ENVIRONMENT` for table data mocking
4. Test authorization checks separately
5. Use `ROLLBACK ENTITIES` in teardown methods

---

## Quick Reference: Save Sequence

```
Interaction Phase:
  Consumer → MODIFY ENTITIES → Transactional Buffer
  Consumer → READ ENTITIES ← Transactional Buffer
  (Determinations on modify execute here)

Save Phase (triggered by COMMIT ENTITIES):
  1. FINALIZE           → Final data preparation
  2. CHECK_BEFORE_SAVE  → Cross-entity validations
  3. Determinations (on save) → Execute pending determinations
  4. Validations (on save)    → Execute pending validations
  5. SAVE_MODIFIED      → Write to database (unmanaged/additional save)
  6. CLEANUP_FINALIZE   → Post-save cleanup
  7. CLEANUP            → Final resource release
```

## Quick Reference: Handler Method Signatures

```abap
" Standard operations
METHODS create_travel     FOR MODIFY IMPORTING entities FOR CREATE Travel.
METHODS update_travel     FOR MODIFY IMPORTING entities FOR UPDATE Travel.
METHODS delete_travel     FOR MODIFY IMPORTING entities FOR DELETE Travel.

" Read
METHODS read_travel       FOR READ IMPORTING keys FOR READ Travel RESULT result.

" Lock
METHODS lock_travel       FOR LOCK IMPORTING keys FOR LOCK Travel.

" Validation
METHODS validateCustomer  FOR VALIDATE ON SAVE
  IMPORTING keys FOR Travel~validateCustomer.

" Determination
METHODS setStatusOpen     FOR DETERMINE ON MODIFY
  IMPORTING keys FOR Travel~setStatusOpen.

" Action
METHODS acceptTravel      FOR MODIFY
  IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

" Instance feature control
METHODS get_instance_features FOR INSTANCE FEATURES
  IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

" Instance authorization
METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
  IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

" Global authorization
METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
  IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

" Early numbering
METHODS earlynumbering_create FOR NUMBERING
  IMPORTING entities FOR CREATE Travel.

" Precheck
METHODS precheck_create FOR PRECHECK
  IMPORTING entities FOR CREATE Travel.
```

## Quick Reference: Saver Method Signatures

```abap
" Saver class (inherits from CL_ABAP_BEHAVIOR_SAVER)
METHODS finalize          REDEFINITION.
METHODS check_before_save REDEFINITION.
METHODS save_modified     REDEFINITION.  " For unmanaged/additional save
METHODS cleanup_finalize  REDEFINITION.
METHODS cleanup           REDEFINITION.
METHODS adjust_numbers    REDEFINITION.  " For late numbering
```

---

## Sources

- [SAP Help - ABAP RESTful Application Programming Model](https://help.sap.com/docs/abap-cloud/abap-rap/abap-restful-application-programming-model)
- [SAP-samples/abap-cheat-sheets - RAP BDL](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/36_RAP_Behavior_Definition_Language.md)
- [SAP-samples/abap-cheat-sheets - EML](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/08_EML_ABAP_for_RAP.md)
- [SAP-samples/abap-cheat-sheets - Unit Tests](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/14_ABAP_Unit_Tests.md)
- [SAP-samples/abap-cheat-sheets - Authorization Checks](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/25_Authorization_Checks.md)
- [SAP Community - RAP Topic Page](https://pages.community.sap.com/topics/abap/rap)
- [SAP Community - Authorizations in RAP](https://community.sap.com/t5/application-development-and-automation-blog-posts/authorizations-in-rap/ba-p/13792683)
- [SAP Community - Feature Control in RAP](https://community.sap.com/t5/application-development-and-automation-blog-posts/feature-control-in-rap-static-feature-control-in-rap-part-1/ba-p/13996503)
- [SAP Community - Side Effects in RAP](https://community.sap.com/t5/application-development-and-automation-blog-posts/side-effects-in-rap-explained-with-determination-example/ba-p/14140206)
- [SAP Community - RAP Events](https://community.sap.com/t5/technology-blog-posts-by-members/rap-events/ba-p/14033263)
- [SAP Community - Determinations in RAP](https://community.sap.com/t5/technology-blog-posts-by-sap/determinations-in-abap-restful-programming-model/ba-p/13489868)
- [SAP Community - RAP Numbering](https://community.sap.com/t5/technology-blog-posts-by-members/rap-numbering-early-numbering-late-numbering-managed-numbering/ba-p/14075168)
- [SAP Community - Augmentation in RAP](https://community.sap.com/t5/technology-blog-posts-by-members/augmentation-operation-in-rap/ba-p/14082109)
- [SAP Community - Build Composition Tree](https://community.sap.com/t5/technology-blog-posts-by-sap/build-composition-tree-with-abap-cds-views/ba-p/13464640)
- [SAP Help - Draft Handling](https://help.sap.com/docs/abap-cloud/abap-rap/draft)
- [SAP Help - Authorization Control](https://help.sap.com/docs/abap-cloud/abap-rap/authorization-control)
- [SAP Help - Strict Mode](https://help.sap.com/docs/abap-cloud/abap-rap/strict-mode)
- [SAP Help - Late Numbering](https://help.sap.com/docs/abap-cloud/abap-rap/late-numbering)
- [SAP Help - Virtual Elements](https://help.sap.com/docs/abap-cloud/abap-rap/using-virtual-elements-in-cds-projection-views)
- [SAP Help - Service Binding](https://help.sap.com/docs/abap-cloud/abap-rap/service-binding)
- [SAP Help - CDS Projection View](https://help.sap.com/docs/abap-cloud/abap-rap/cds-projection-view)
- [SAP Help - Unmanaged Save](https://help.sap.com/docs/abap-cloud/abap-rap/defining-unmanaged-save-in-behavior-definition)
- [SAP Help - Save Sequence (save_modified)](https://help.sap.com/doc/abapdocu_latest_index_htm/latest/en-US/abaprap_saver_meth_save_modified.htm)
- [SAP Community - Managed vs Unmanaged RAP BOs](https://community.sap.com/t5/technology-blog-posts-by-members/sap-clean-core-development-managed-vs-unmanaged-rap-business-objects/ba-p/14017960)
- [SAP Community - Managed with Unmanaged Save](https://community.sap.com/t5/technology-blog-posts-by-sap/how-to-develop-managed-business-object-with-unmanaged-save-functionality-in/ba-p/13536553)
- [Discovering ABAP - Managed with Unmanaged Save](https://discoveringabap.com/2023/02/06/abap-restful-application-programming-model-17-managed-with-unmanaged-save/)
- [SAP Tutorials - RAP Unit Testing](https://developers.sap.com/tutorials/abap-environment-rap100-unit-testing..html)
- [SAP Tutorials - Factory Action](https://developers.sap.com/tutorials/abap-environment-rap100-factory-action..html)
- [SAP Community - Draft Tables](https://community.sap.com/t5/application-development-and-automation-blog-posts/understanding-and-using-draft-tables-in-sap-s-rap-model/ba-p/13882473)
- [SAP Community - RAP Validation and Precheck](https://sachinartani.com/blog/sap-rap-validation-and-precheck)
- [eLearning Solutions - Common Mistakes in SAP RAP](https://www.elearningsolutions.co.in/common-mistakes-in-sap-rap-and-how-to-avoid-them/)
- [SAP Community - ABAP Cloud FAQ](https://pages.community.sap.com/topics/abap/abap-cloud-faq)
- [Software Heroes - RAP Custom Entity](https://software-heroes.com/en/blog/abap-rap-custom-entity-en)
- [SAP Community - RAP Composition vs Association](https://luxten.in/abap-rap-composition-vs-association/)
- [SAP Community - Deep Action OData V4](https://community.sap.com/t5/technology-blog-posts-by-members/rap-with-deep-static-action-odata-v4-complete-guide-till-execution-in/ba-p/14170270)
