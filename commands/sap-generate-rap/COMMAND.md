---
name: sap-generate-rap
description: Generate RAP Business Object scaffold from entity name. Creates CDS data model, projection, behavior definition, handler class, and test class.
allowed-tools: Read Write Bash
---

# /sap-generate-rap [EntityName] [options]

Generate a complete RAP Business Object scaffold.

## Arguments
- `EntityName` (required): Business entity name, e.g., `SalesOrder`, `Product`, `Employee`
- `--managed` (default): Managed RAP BO with draft
- `--unmanaged`: Unmanaged RAP BO
- `--readonly`: Read-only projection (no CUD)
- `--prefix Z` (default: Z): Namespace prefix
- `--draft` (default: true): Include draft handling
- `--auth` (default: true): Include authorization control

## Generated Files

```
{{PREFIX}}I_{{Entity}}.asddls            — Interface CDS view entity (R-layer)
{{PREFIX}}C_{{Entity}}.asddls            — Consumption CDS projection (C-layer)
{{PREFIX}}I_{{Entity}}.bdef              — Interface behavior definition
{{PREFIX}}C_{{Entity}}.bdef              — Projection behavior definition
{{PREFIX}}CL_BP_{{Entity}}.abap          — Behavior handler class
{{PREFIX}}CL_{{Entity}}_TEST.abap        — ABAP Unit test class
{{PREFIX}}T_{{Entity}}.asddls            — Database table definition
{{PREFIX}}CI_{{Entity}}_D_{{Entity}}.asddls — Draft table (if --draft)
```

## Template: Managed RAP BO with Draft

### Database Table
```cds
@EndUserText.label: '{{Entity}} Database Table'
@AbapCatalog.enhancement.category: #NOT_EXTENSIBLE
@AbapCatalog.tableCategory: #TRANSPARENT
@AbapCatalog.deliveryClass: #A
define table {{prefix}}t_{{entity_lower}} {
  key client    : abap.clnt not null;
  key uuid      : sysuuid_x16 not null;
  id            : abap.char(10);
  description   : abap.char(100);
  status        : abap.char(1);
  created_by    : abp_creation_user;
  created_at    : abp_creation_tstmpl;
  last_changed_by : abp_locinst_lastchange_user;
  last_changed_at : abp_locinst_lastchange_tstmpl;
  local_last_changed_at : abp_lastchange_tstmpl;
}
```

### Interface CDS View Entity
```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '{{Entity}}'
define root view entity {{PREFIX}}I_{{Entity}}
  as select from {{prefix}}t_{{entity_lower}}
{
  key uuid              as UUID,
      id                as ID,
      description       as Description,
      status            as Status,
      @Semantics.user.createdBy: true
      created_by        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at        as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by   as LastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at   as LastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
```

### Behavior Definition
```
managed implementation in class {{PREFIX}}CL_BP_{{Entity}} unique;
strict ( 2 );
with draft;

define behavior for {{PREFIX}}I_{{Entity}} alias {{Entity}}
persistent table {{prefix}}t_{{entity_lower}}
draft table {{PREFIX}}D_{{Entity}}
etag master LocalLastChangedAt
lock master total etag LastChangedAt
authorization master ( global )
{
  field ( readonly ) UUID, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt, LocalLastChangedAt;
  field ( numbering : managed ) UUID;

  create;
  update;
  delete;

  draft action Activate optimized;
  draft action Discard;
  draft action Edit;
  draft action Resume;
  draft determine action Prepare;

  determination setDefaults on modify { create; }
  validation validateID on save { create; update; field ID; }

  mapping for {{prefix}}t_{{entity_lower}}
  {
    UUID = uuid;
    ID = id;
    Description = description;
    Status = status;
    CreatedBy = created_by;
    CreatedAt = created_at;
    LastChangedBy = last_changed_by;
    LastChangedAt = last_changed_at;
    LocalLastChangedAt = local_last_changed_at;
  }
}
```

### Handler Class (skeleton)
```abap
CLASS {{PREFIX}}cl_bp_{{entity_lower}} DEFINITION PUBLIC ABSTRACT FINAL
  FOR BEHAVIOR OF {{PREFIX}}i_{{entity_lower}}.
ENDCLASS.

CLASS {{PREFIX}}cl_bp_{{entity_lower}} IMPLEMENTATION.
ENDCLASS.

CLASS lhc_{{entity_lower}} DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations
      FOR {{Entity}} RESULT result.

    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR {{Entity}}~setDefaults.

    METHODS validateID FOR VALIDATE ON SAVE
      IMPORTING keys FOR {{Entity}}~validateID.
ENDCLASS.

CLASS lhc_{{entity_lower}} IMPLEMENTATION.
  METHOD get_global_authorizations.
    " TODO: implement authorization check
    result = VALUE #( %action-create = if_abap_behv=>auth-allowed
                      %action-update = if_abap_behv=>auth-allowed
                      %action-delete = if_abap_behv=>auth-allowed ).
  ENDMETHOD.

  METHOD setDefaults.
    READ ENTITIES OF {{PREFIX}}i_{{entity_lower}} IN LOCAL MODE
      ENTITY {{Entity}} FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    MODIFY ENTITIES OF {{PREFIX}}i_{{entity_lower}} IN LOCAL MODE
      ENTITY {{Entity}} UPDATE
        FIELDS ( Status )
        WITH VALUE #( FOR entity IN entities
          ( %tky = entity-%tky Status = 'N' ) )
      REPORTED DATA(reported).
  ENDMETHOD.

  METHOD validateID.
    READ ENTITIES OF {{PREFIX}}i_{{entity_lower}} IN LOCAL MODE
      ENTITY {{Entity}} FIELDS ( ID ) WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      IF <entity>-ID IS INITIAL.
        APPEND VALUE #( %tky = <entity>-%tky ) TO failed-{{entity_lower}}.
        APPEND VALUE #( %tky = <entity>-%tky
                        %msg = new_message_with_text( text = 'ID is required' severity = if_abap_behv_message=>severity-error )
                        %element-ID = if_abap_behv=>mk-on )
          TO reported-{{entity_lower}}.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

## Execution Steps

1. Parse arguments (entity name, options)
2. Generate all template files with placeholder replacement
3. Write files to current directory or `src/` subdirectory
4. Print summary of generated files
