# Behavior Definition (BDEF) — Complete Syntax Reference

## Table of Contents
- [Header Options](#header-options) | [Entity Definition](#entity-definition) | [Standard Operations](#standard-operations)
- [Field Characteristics](#field-characteristics) | [Validations](#validations) | [Prechecks](#prechecks)
- [Determinations](#determinations) | [Actions](#actions) | [Determine Actions](#determine-actions)
- [Side Effects](#side-effects) | [Draft Handling](#draft-handling) | [Composition](#composition-parent-child)
- [Mapping](#mapping) | [Business Events](#business-events) | [Complete Example](#complete-example)

## Header Options

```cds
managed                              // Implementation type
  implementation in class zbp_i_entity unique;  // Handler class
strict ( 2 );                        // Strict mode (1 or 2)
with draft;                          // Enable draft handling

// Alternative implementation types:
// unmanaged implementation in class zbp_i_entity unique;
// managed with additional save implementation in class zbp_i_entity unique;
// managed with unmanaged save implementation in class zbp_i_entity unique;
```

### Strict Modes
| Mode | Rules | Use When |
|------|-------|----------|
| `strict ( 1 )` | Basic RAP rules enforced | S/4HANA on-premise |
| `strict ( 2 )` | Stricter rules + new syntax required | BTP ABAP Environment (recommended) |
| No strict | Legacy compatibility | Existing RAP BOs only |

## Entity Definition

```cds
define behavior for ZI_Entity alias Entity
  // Persistence
  persistent table ztab_entity         // Active data table
  draft table zdraft_entity            // Draft table (if with draft)

  // Concurrency Control
  etag master LocalLastChangedAt       // Optimistic locking (required)
  lock master                          // Lock owner (root entity)
  total etag LastChangedAt             // Total etag for draft

  // Authorization
  authorization master ( global )                    // Global only
  authorization master ( instance )                  // Instance only
  authorization master ( global, instance )          // Both (recommended)
  authorization dependent by _Parent                 // Delegate to parent

  // Numbering
  // (none)                             // External numbering (client provides key)
  // early numbering                    // Framework assigns key on create
  // late numbering                     // Key assigned at save time
{
  // ... behavior body ...
}
```

## Standard Operations

```cds
  create;                              // Enable create
  update;                              // Enable update
  delete;                              // Enable delete

  // With field control for specific operations:
  create ( features : global );        // Create with global feature control
  update ( features : instance );      // Update with instance feature control
```

## Field Characteristics

```cds
  // Read-only fields (cannot be set by client)
  field ( readonly ) EntityUUID, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt;

  // Mandatory fields (must be provided)
  field ( mandatory ) Description, Status;

  // Numbering (framework provides value)
  field ( numbering : managed ) EntityUUID;  // UUID auto-generated

  // Read-only on update (set on create, read-only after)
  field ( readonly : update ) EntityType;

  // Features (dynamic read-only via feature control method)
  field ( features : instance ) Status, Priority;
```

## Validations

```cds
  // Trigger: on save (runs when COMMIT ENTITIES is called)
  validation ValidateDescription on save { field Description; }
  validation ValidateDates on save { field BeginDate, EndDate; }
  validation ValidateStatus on save { create; field Status; }

  // Multiple triggers
  validation ValidateAll on save { create; update; field Field1, Field2; }
```

**Handler signature:**
```abap
METHODS validateDescription FOR VALIDATE ON SAVE
  IMPORTING keys FOR Entity~ValidateDescription.
```

## Prechecks

```cds
  // Like validation but runs BEFORE the operation (can prevent it)
  precheck create;
  precheck update;
  precheck delete;
```

| Aspect | Validation | Precheck |
|--------|-----------|----------|
| Timing | After modifications, at save | Before the operation starts |
| Can prevent operation | Via `failed` parameter | Via `failed` parameter |
| Access to data | Full buffer access | Limited (keys + operation type) |
| Use case | Business rule checks | Authorization, existence checks |

## Determinations

```cds
  // on modify: runs immediately when data changes
  determination SetDefaults on modify { create; }
  determination CalcTotal on modify { field Quantity, Price; }

  // on save: runs during save sequence (after validations)
  determination SetFinalStatus on save { field Status; }
  determination GenerateID on save { create; }
```

**Trigger types:**
- `{ create; }` — triggered on entity creation
- `{ update; }` — triggered on entity update
- `{ delete; }` — triggered on entity deletion
- `{ field Field1, Field2; }` — triggered when specific fields change

## Actions

```cds
  // Instance action (operates on specific instances)
  action Accept result [1] $self;
  action Reject result [1] $self;

  // Instance action with parameter
  action SetPriority parameter ZA_PriorityParam result [1] $self;

  // Instance action with feature control
  action ( features : instance ) Accept result [1] $self;

  // Static action (no instance context)
  static action CreateFromTemplate parameter ZA_TemplateParam result [1] $self;

  // Factory action (creates new instance)
  factory action CopyEntity [1];

  // Internal action (only callable from within BO, not exposed via API)
  internal action RecalculateTotals;

  // Deep action (with complex input structure)
  action SubmitWithItems deep parameter ZA_SubmitParam result [1] $self;
```

**Handler signatures:**
```abap
" Instance action
METHODS accept FOR MODIFY
  IMPORTING keys FOR ACTION Entity~Accept RESULT result.

" Static action
METHODS createFromTemplate FOR MODIFY
  IMPORTING keys FOR ACTION Entity~CreateFromTemplate RESULT result.

" Factory action
METHODS copyEntity FOR MODIFY
  IMPORTING keys FOR ACTION Entity~CopyEntity.
```

## Determine Actions

```cds
  // Determine action: validation-like logic that also modifies data
  // Used in draft scenarios for "Prepare" action
  determine action Prepare
  {
    validation ValidateDescription;
    validation ValidateDates;
    determination CalcTotal;
  }
```

## Side Effects

```cds
  side effects
  {
    // When these fields change → refresh these fields on UI
    field Quantity affects field TotalPrice;
    field Price affects field TotalPrice;

    // When these fields change → refresh these entities
    field Status affects entity _Booking;

    // When action executes → refresh
    action Accept affects field Status, field OverallStatus;

    // Trigger determination on field change
    determine action Prepare executed on field BeginDate, field EndDate;
  }
```

## Draft Handling

```cds
  // Standard draft actions (all required for draft-enabled BOs)
  draft action Resume;                  // Resume editing existing draft
  draft action Edit;                    // Create draft from active instance
  draft action Activate optimized;      // Move draft to active (optimized skips unchanged)
  draft action Discard;                 // Delete draft, unlock active

  // Prepare action (validates draft before activation)
  draft determine action Prepare
  {
    validation ValidateDescription;
    validation ValidateDates;
  }
```

## Composition (Parent-Child)

```cds
define behavior for ZI_Travel alias Travel
  ...
{
  // Parent declares composition
  association _Booking { create; with draft; }
}

define behavior for ZI_Booking alias Booking
  ...
  lock dependent by _Travel
  authorization dependent by _Travel
  etag master LocalLastChangedAt
{
  // Child operations
  update; delete;

  // Child references parent
  association _Travel { with draft; }

  // Field control inherited from parent
  field ( readonly ) TravelUUID;
}
```

## Mapping

```cds
  // Auto-map CDS fields to DB table fields
  mapping for ztab_entity corresponding;

  // Explicit mapping (when names differ)
  mapping for ztab_entity
  {
    EntityUUID = entity_uuid;
    Description = descr;
    Status = stat;
  }

  // Control mapping (for %control structure)
  mapping for ztab_entity corresponding
  {
    EntityUUID = entity_uuid;
    Description = descr;
  }
```

## Business Events

```cds
  // Raise event after save
  event EntityCreated parameter ZA_EntityCreatedParam;
  event EntityAccepted parameter ZA_EntityAcceptedParam;
```

**Abstract entity for event parameter:**
```cds
define abstract entity ZA_EntityCreatedParam
{
  EntityUUID  : sysuuid_x16;
  EntityID    : abap.numc(8);
  CreatedBy   : syuname;
  CreatedAt   : timestampl;
}
```

**Raising in saver class:**
```abap
METHOD save_modified.
  IF create-entity IS NOT INITIAL.
    RAISE ENTITY EVENT zi_entity~EntityCreated
      FROM VALUE #( FOR <c> IN create-entity
        ( EntityUUID = <c>-EntityUUID
          EntityID   = <c>-EntityID
          CreatedBy  = <c>-CreatedBy
          CreatedAt  = <c>-CreatedAt ) ).
  ENDIF.
ENDMETHOD.
```

## Complete Example

```cds
managed implementation in class zbp_i_travel unique;
strict ( 2 );
with draft;

define behavior for ZI_Travel alias Travel
persistent table ztab_travel
draft table zdraft_travel
etag master LocalLastChangedAt
lock master total etag LastChangedAt
authorization master ( global, instance )
{
  field ( readonly ) TravelUUID, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt;
  field ( numbering : managed ) TravelUUID;
  field ( mandatory ) AgencyID, CustomerID, BeginDate, EndDate;
  field ( features : instance ) OverallStatus;

  create; update; delete;

  determination SetStatusNew on modify { create; }
  determination CalcTotalPrice on modify { field BookingFee, CurrencyCode; }

  validation ValidateCustomer on save { field CustomerID; }
  validation ValidateDates on save { field BeginDate, EndDate; }

  action ( features : instance ) AcceptTravel result [1] $self;
  action ( features : instance ) RejectTravel result [1] $self;
  internal action RecalcTotal;

  event TravelCreated parameter ZA_TravelCreated;
  event TravelAccepted parameter ZA_TravelAccepted;

  side effects
  {
    field BookingFee affects field TotalPrice;
    action AcceptTravel affects field OverallStatus;
  }

  association _Booking { create; with draft; }

  draft action Resume;
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft determine action Prepare
  {
    validation ValidateCustomer;
    validation ValidateDates;
  }

  mapping for ztab_travel corresponding;
}

define behavior for ZI_Booking alias Booking
persistent table ztab_booking
draft table zdraft_booking
etag master LocalLastChangedAt
lock dependent by _Travel
authorization dependent by _Travel
{
  field ( readonly ) BookingUUID, TravelUUID;
  field ( numbering : managed ) BookingUUID;
  field ( mandatory ) CarrierID, ConnectionID, FlightDate;

  update; delete;

  determination SetBookingDate on modify { create; }
  validation ValidateConnection on save { field CarrierID, ConnectionID, FlightDate; }

  association _Travel { with draft; }

  mapping for ztab_booking corresponding;
}
```
