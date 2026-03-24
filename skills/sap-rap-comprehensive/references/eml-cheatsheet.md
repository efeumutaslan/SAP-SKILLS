# EML (Entity Manipulation Language) — Quick Reference

## Table of Contents
- [Key Concepts](#key-concepts) | [READ ENTITIES](#read-entities) | [MODIFY ENTITIES](#modify-entities)
- [COMMIT ENTITIES](#commit-entities) | [ROLLBACK ENTITIES](#rollback-entities) | [Draft-Specific EML](#draft-specific-eml)
- [Response Structures](#response-structures) | [Common Patterns](#common-patterns-in-handler-methods)

## Key Concepts

| Symbol | Meaning | Usage |
|--------|---------|-------|
| `%cid` | Content ID | Temporary key for new instances (within one EML block) |
| `%cid_ref` | Content ID reference | Reference parent's %cid in create-by-association |
| `%tky` | Transactional key | Full key including %is_draft (for draft-enabled BOs) |
| `%key` | Business key | Only the business key fields |
| `%pid` | Preliminary ID | Late numbering: temporary key before real key is assigned |
| `%control` | Field control | Indicates which fields were actually sent by client |
| `%param` | Action parameter | Input/output parameter for actions |
| `%is_draft` | Draft indicator | '01' = draft, '00' = active |
| `IN LOCAL MODE` | Skip auth checks | Used inside handler methods to avoid re-checking |

## READ ENTITIES

### Read specific fields
```abap
READ ENTITIES OF zi_travel
  ENTITY Travel
  FIELDS ( AgencyID CustomerID BeginDate EndDate )
  WITH VALUE #( ( TravelUUID = lv_uuid ) )
  RESULT DATA(lt_travels)
  FAILED DATA(ls_failed).
```

### Read all fields
```abap
READ ENTITIES OF zi_travel
  ENTITY Travel
  ALL FIELDS
  WITH CORRESPONDING #( keys )
  RESULT DATA(lt_travels).
```

### Read by association (navigate to child)
```abap
READ ENTITIES OF zi_travel
  ENTITY Travel BY \_Booking
  ALL FIELDS
  WITH VALUE #( ( TravelUUID = lv_uuid ) )
  RESULT DATA(lt_bookings).
```

### Read in local mode (inside handlers)
```abap
READ ENTITIES OF zi_travel IN LOCAL MODE
  ENTITY Travel
  FIELDS ( Status )
  WITH CORRESPONDING #( keys )
  RESULT DATA(lt_travels).
```

## MODIFY ENTITIES

### Create
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate )
  WITH VALUE #( (
    %cid       = 'NEW_1'
    AgencyID   = '70001'
    CustomerID = '100000'
    BeginDate  = '20260401'
    EndDate    = '20260415'
  ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Create multiple
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID )
  WITH VALUE #(
    ( %cid = 'T1' AgencyID = '70001' CustomerID = '100000' )
    ( %cid = 'T2' AgencyID = '70002' CustomerID = '100001' )
    ( %cid = 'T3' AgencyID = '70003' CustomerID = '100002' )
  )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Update
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  UPDATE FIELDS ( Status Description )
  WITH VALUE #( (
    TravelUUID  = lv_uuid
    Status      = 'A'
    Description = 'Updated description'
  ) )
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Update with %control (only specified fields)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  UPDATE
  WITH VALUE #( (
    TravelUUID   = lv_uuid
    Status       = 'A'
    %control-Status = if_abap_behv=>mk-on
  ) )
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Delete
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  DELETE FROM VALUE #( ( TravelUUID = lv_uuid ) )
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Execute action
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE AcceptTravel
  FROM VALUE #( ( TravelUUID = lv_uuid ) )
  RESULT DATA(lt_result)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Execute action with parameter
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE SetPriority
  FROM VALUE #( (
    TravelUUID = lv_uuid
    %param     = VALUE #( Priority = 'H' )
  ) )
  RESULT DATA(lt_result)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Create by association (create child with parent)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  CREATE BY \_Booking
  FIELDS ( CarrierID ConnectionID FlightDate )
  WITH VALUE #( (
    TravelUUID = lv_travel_uuid    " Parent key
    %target    = VALUE #( (
      %cid         = 'BOOK_1'
      CarrierID    = 'LH'
      ConnectionID = '0400'
      FlightDate   = '20260401'
    ) )
  ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

### Create parent + child in one call
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  CREATE FIELDS ( AgencyID CustomerID )
  WITH VALUE #( (
    %cid     = 'TRAVEL_1'
    AgencyID = '70001'
    CustomerID = '100000'
  ) )
  CREATE BY \_Booking
  FIELDS ( CarrierID ConnectionID FlightDate )
  WITH VALUE #( (
    %cid_ref = 'TRAVEL_1'        " Reference parent's %cid
    %target  = VALUE #( (
      %cid       = 'BOOK_1'
      CarrierID  = 'LH'
      ConnectionID = '0400'
      FlightDate = '20260401'
    ) )
  ) )
  MAPPED DATA(ls_mapped)
  FAILED DATA(ls_failed)
  REPORTED DATA(ls_reported).
```

## COMMIT ENTITIES

### Basic commit
```abap
COMMIT ENTITIES.
```

### Commit with response
```abap
COMMIT ENTITIES
  RESPONSE OF zi_travel
  FAILED DATA(ls_commit_failed)
  REPORTED DATA(ls_commit_reported).
```

### Check commit success
```abap
IF ls_commit_failed-travel IS NOT INITIAL.
  " Save failed — check reported messages
  LOOP AT ls_commit_reported-travel INTO DATA(ls_msg).
    " Process error messages
  ENDLOOP.
ENDIF.
```

## ROLLBACK ENTITIES

```abap
" Undo all changes in current LUW (used in test cleanup)
ROLLBACK ENTITIES.
```

## Draft-Specific EML

### Edit (create draft from active)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE Edit
  FROM VALUE #( ( TravelUUID = lv_uuid  %is_draft = if_abap_behv=>mk-off ) )
  MAPPED DATA(ls_mapped).
" ls_mapped contains the draft instance key (%is_draft = '01')
```

### Activate (promote draft to active)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE Activate
  FROM VALUE #( ( TravelUUID = lv_uuid  %is_draft = if_abap_behv=>mk-on ) )
  MAPPED DATA(ls_mapped).
```

### Discard (delete draft)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE Discard
  FROM VALUE #( ( TravelUUID = lv_uuid  %is_draft = if_abap_behv=>mk-on ) )
  MAPPED DATA(ls_mapped).
```

### Prepare (validate draft)
```abap
MODIFY ENTITIES OF zi_travel
  ENTITY Travel
  EXECUTE Prepare
  FROM VALUE #( ( TravelUUID = lv_uuid  %is_draft = if_abap_behv=>mk-on ) )
  MAPPED DATA(ls_mapped).
```

## Response Structures

### MAPPED
```abap
" After CREATE, contains assigned keys
ls_mapped-travel    " Table of: %cid, TravelUUID (the new key)
ls_mapped-booking   " Table of: %cid, BookingUUID
```

### FAILED
```abap
" Contains failed instances
ls_failed-travel    " Table of: %tky, %fail-cause (e.g., unauthorized, not_found)
```

### REPORTED
```abap
" Contains messages
ls_reported-travel  " Table of: %tky, %msg (IF_ABAP_BEHV_MESSAGE reference)
```

## Common Patterns in Handler Methods

### Pattern: Read → Check → Modify → Report
```abap
METHOD validateSomething.
  " 1. Read current data
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( Field1 Field2 )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  " 2. Check business rules
  LOOP AT lt_travels INTO DATA(ls_travel).
    IF ls_travel-Field1 > ls_travel-Field2.

      " 3. Report failure
      APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
      APPEND VALUE #( %tky = ls_travel-%tky
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text = 'Field1 must not exceed Field2' )
        %element-Field1 = if_abap_behv=>mk-on
      ) TO reported-travel.
    ENDIF.
  ENDLOOP.
ENDMETHOD.
```

### Pattern: Read → Modify → Return result (for actions)
```abap
METHOD doAction.
  " 1. Modify state
  MODIFY ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( Status )
    WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'A' ) ).

  " 2. Read updated data
  READ ENTITIES OF zi_travel IN LOCAL MODE
    ENTITY Travel ALL FIELDS
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  " 3. Return result
  result = VALUE #( FOR travel IN lt_travels
    ( %tky = travel-%tky  %param = travel ) ).
ENDMETHOD.
```
