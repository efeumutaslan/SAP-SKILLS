# SAP S/4HANA Extensibility Patterns - Comprehensive Research

> Research Date: 2026-03-23
> Purpose: Foundation for creating the most complete S/4HANA extensibility skill guide
> Sources: SAP Community, SAP Help Portal, SAP News Center, SAP Learning, SAP Developer Tutorials, GitHub SAP-samples

---

## TABLE OF CONTENTS

1. [Clean Core Strategy & Principles](#1-clean-core-strategy--principles)
2. [Four-Level Extensibility Model (A-D)](#2-four-level-extensibility-model-a-d)
3. [Release Contracts (C0-C3)](#3-release-contracts-c0-c3)
4. [Extensibility Types Overview](#4-extensibility-types-overview)
5. [Key User (In-App) Extensibility](#5-key-user-in-app-extensibility)
6. [Developer Extensibility (Embedded Steampunk)](#6-developer-extensibility-embedded-steampunk)
7. [Side-by-Side Extensibility (SAP BTP)](#7-side-by-side-extensibility-sap-btp)
8. [BAdI Patterns in S/4HANA Cloud](#8-badi-patterns-in-s4hana-cloud)
9. [Custom Business Objects (CBO)](#9-custom-business-objects-cbo)
10. [ABAP Cloud Development Model & RAP](#10-abap-cloud-development-model--rap)
11. [S/4HANA Cloud Public vs Private vs On-Premise](#11-s4hana-cloud-public-vs-private-vs-on-premise)
12. [Cloudification Repository & Released APIs](#12-cloudification-repository--released-apis)
13. [ATC Cloud Readiness Checks](#13-atc-cloud-readiness-checks)
14. [CDS View Extensions](#14-cds-view-extensions)
15. [SAP Extensibility Wizard](#15-sap-extensibility-wizard)
16. [Best Practices](#16-best-practices)
17. [Anti-Patterns](#17-anti-patterns)
18. [Common Errors & Troubleshooting](#18-common-errors--troubleshooting)
19. [2025-2026 Timeline & Roadmap](#19-2025-2026-timeline--roadmap)

---

## 1. Clean Core Strategy & Principles

### Core Definition
Clean core is a framework of best practices that keeps both the SAP S/4HANA Cloud solution and its extensions upgrade-stable. It promotes a standardized, upgrade-stable, and extensible system by minimizing custom modifications and adhering to SAP's extensibility frameworks.

### Five Pillars of Clean Core
1. **Zero-Modification Policy** - No modifications to SAP standard code from day one
2. **Minimize Extensions** - Use the extensibility framework; question every deviation from standard
3. **API-First Strategy** - Use only released, whitelisted APIs
4. **Leverage SAP BTP for Innovation** - Push complex/innovative extensions to BTP
5. **Eliminate Redundant Enhancements** - Remove enhancements that duplicate standard functionality

### Key Principles
- Separation of SAP code and custom extensions via mandatory publicly released SAP APIs and extension points
- All extensions must be upgrade-stable and lifecycle-safe
- Extensions should not block or delay system upgrades
- Standard SAP functionality should be preferred over custom development
- Every custom extension needs documented business justification

### Evolution (2024-2026)
- SAP evolved from a simple three-tier model to the four-level (A-D) Clean Core maturity framework
- Formalized in August 2025 to give teams a structured classification for every extension
- The approach now provides a consistent way to manage upgrade risk
- AI-driven Custom Code Migration capability expanding substantially through 2026

---

## 2. Four-Level Extensibility Model (A-D)

The new maturity model categorizes extensions into four levels based on architectural integrity, upgrade safety, and alignment with clean core principles.

### Level A - Fully Compliant (Target State)
- **Definition**: Extensions using ONLY publicly released and stable SAP interfaces with formal stability contracts
- **On-stack**: Built within SAP S/4HANA Cloud using the ABAP Cloud development model with publicly released APIs
- **Side-by-side**: Built on SAP BTP using released remote APIs
- **Upgrade Impact**: Zero - fully upgrade-safe
- **Recommendation**: TARGET for all new development
- **Examples**: RAP-based applications using released CDS views, BAdI implementations via developer extensibility, BTP extensions using released OData/SOAP APIs

### Level B - Compliant (Acceptable with Governance)
- **Definition**: Extensions using SAP's classic APIs and technologies that are well-defined, documented, and generally upgrade-stable
- **Interfaces**: Classic BAPIs, classic function modules, documented data dictionary objects
- **Upgrade Impact**: Low to moderate - generally stable but no formal contract
- **Recommendation**: Acceptable with governance sign-off and appropriate monitoring
- **Examples**: Classic BAPI calls, classic enhancement implementations using documented APIs

### Level C - Partially Compliant (Remediation Needed)
- **Definition**: Extensions accessing SAP internal objects, offering flexibility for legacy scenarios
- **Upgrade Impact**: Meaningful risk - SAP plans changelog for SAP objects to help identify changes early
- **Recommendation**: Belongs on a documented remediation roadmap, NOT in permanent architecture
- **Examples**: Direct access to SAP internal tables, use of non-released function modules, reading internal CDS views

### Level D - Non-Compliant (Retire ASAP)
- **Definition**: Extensions using explicitly non-recommended objects or techniques
- **Includes**: Modifications, implicit enhancements, direct writes to SAP tables
- **Upgrade Impact**: Severe exposure
- **Recommendation**: Establish retirement timeline wherever they exist
- **Examples**: SAP source code modifications, implicit enhancements, direct INSERT/UPDATE/DELETE on SAP tables, kernel modifications

---

## 3. Release Contracts (C0-C3)

Release contracts classify repository objects as released APIs and ensure stability guarantees.

### C0 - Developer Extensibility Contract
- **Purpose**: Allows adding enhancement fields at specified extension points
- **Use Case**: Extending CDS views in a controlled manner
- **Key Feature**: Enables structure extension (adding new fields/elements)
- **For CDS Views**: Allows extend view statements to add elements from underlying data sources
- **For Behavior Definitions**: Technically possible but rare in practice; only if provider explicitly enables extension anchors
- **For Tables**: Tables can be prepared for C0 using specific annotations and release state settings (opt-in)

### C1 - System-Internal Use Contract
- **Purpose**: Stable API for internal consumption within the same system
- **Use Case**: CDS views, classes, interfaces consumed by custom code on-stack
- **Key Feature**: Safe to consume inside the system but NOT open for developer extensions
- **Scope**: The CDS view/object is stable for reading/calling but cannot be structurally extended
- **Field Extensions**: Field length extensions are possible in C1

### C2 - Remote API Contract
- **Purpose**: Published for remote consumption (external systems)
- **Use Case**: Side-by-side integrations, third-party system access
- **Key Feature**: Ensures technical stability of the external API
- **Scope**: OData services, SOAP services exposed for external consumption
- **Restriction**: Field length extensions are NOT possible in C2

### C3 - Manage Configuration Content Contract
- **Purpose**: For database tables that hold configuration/customizing data
- **Use Case**: Maintaining configuration entries in tables
- **Key Feature**: SAP most often delivers database tables with C3 contract
- **Scope**: Allows content management (insert/update/delete of configuration records)

### Practical Rules
- Only objects with release contracts can be used in ABAP Cloud development
- The ABAP syntax check validates that consumed objects have appropriate release contracts
- Released objects appear under "Released Objects" category in ADT project explorer
- Custom objects can also be released with contracts (e.g., custom CDS with C1 for reuse)

---

## 4. Extensibility Types Overview

### Three Major Categories

| Type | Who | Where | Tools | Complexity |
|------|-----|-------|-------|------------|
| **Key User (In-App)** | Business users, functional consultants | Within S/4HANA system | Fiori apps (no-code) | Low |
| **Developer (On-Stack)** | ABAP developers | Within S/4HANA ABAP environment | ADT (Eclipse), ABAP Cloud | Medium-High |
| **Side-by-Side** | Full-stack developers | SAP BTP | SAP BAS, CAP, Node.js, Java | High |

### Decision Criteria
1. **Small change by key user?** -> Key User Extensibility
2. **Custom ABAP development project?** -> Developer Extensibility
3. **Complex/innovative/decoupled app?** -> Side-by-Side on BTP
4. **Partner SaaS application?** -> Side-by-Side on BTP
5. **Integration with external systems?** -> Side-by-Side on BTP
6. **Need AI/ML/IoT capabilities?** -> Side-by-Side on BTP

---

## 5. Key User (In-App) Extensibility

### Overview
In-app extensibility allows adapting standard functionality without external tools. All performed through SAP Fiori Launchpad apps. No coding experience required.

### Available Fiori Apps for Key User Extensibility

#### Custom Fields and Logic
- **App**: "Custom Fields" (F1481)
- Add custom fields to standard business objects
- Fields automatically appear in associated UIs, analytical reports, and OData services
- Custom logic can be added via "Custom Logic" app (Before Save / After Save events)
- For security, allowed ABAP statements are restricted

#### Custom Business Objects (see Section 9)
- **App**: "Custom Business Objects" (F2626)
- Create new business entities with database tables, CDS views, OData services, and UIs

#### Custom CDS Views
- **App**: "Custom CDS Views" (F3835)
- Create analytical and transactional CDS views
- Read access only

#### UI Adaptation
- **App**: Various UI adaptation tools
- Rearrange, hide, or show fields on Fiori UIs
- No code changes needed
- Changes are upgrade-safe

#### Custom Analytical Queries
- Create custom analytical queries based on released CDS views
- Used for embedded analytics

#### Custom Communication Arrangements
- Set up communication scenarios for integration

#### Custom Catalog Extensions
- Assign generated UIs to business catalogs for user access

### Restrictions in Key User Extensibility
- Limited ABAP syntax available in Custom Logic
- No DB operations except SELECT from released views
- No COMMIT WORK statement
- Only whitelisted released APIs can be called
- No access to SAP internal objects

---

## 6. Developer Extensibility (Embedded Steampunk)

### Overview
Developer Extensibility (aka "Embedded Steampunk") allows ABAP Cloud development directly within the S/4HANA system. Uses the ABAP Cloud development model with ADT (ABAP Development Tools for Eclipse).

### Availability
- **S/4HANA Cloud Public Edition**: Available (ABAP Environment / Embedded Steampunk)
- **S/4HANA Cloud Private Edition**: Available since S/4HANA 2022 release
- **S/4HANA On-Premise**: Available since S/4HANA 2022 release

### Key Capabilities
- Create custom ABAP classes, CDS views, service definitions, service bindings
- Implement released BAdIs (cloud BAdIs)
- Build RAP-based Fiori applications
- Create custom APIs (OData, SOAP)
- Full access to ABAP Development Tools (ADT) including ABAP Debugger
- Consume both released objects and released APIs

### Development Rules (ABAP Cloud Restrictions)
- **Only released APIs**: Can only use SAP objects marked with release contracts
- **Restricted ABAP syntax**: No classic dynpro, no classic ALV, no CALL TRANSACTION, etc.
- **No SAP internal access**: Cannot read/write SAP internal tables or call non-released FMs
- **ABAP syntax check enforces**: Automatic validation against whitelist of released objects
- **RAP mandatory**: New transactional apps must use ABAP RESTful Application Programming Model
- **CDS-based data models**: Must use CDS views, not direct table access for SAP data

### Development Workflow
1. Open ADT (Eclipse) and connect to S/4HANA ABAP environment
2. Create an ABAP package in customer namespace (Z*, Y*)
3. Use "Released Objects" in project explorer to find available APIs
4. Develop using ABAP Cloud syntax (automatically checked)
5. Build RAP-based applications or BAdI implementations
6. Activate, test, and transport

---

## 7. Side-by-Side Extensibility (SAP BTP)

### Overview
Extensions built on SAP Business Technology Platform (BTP) that run independently from the S/4HANA core system. Communicate via released remote APIs.

### Key Benefits
- Decoupled lifecycle (independent deployment and updates)
- Access to latest technologies: AI, ML, IoT, analytics
- Multiple runtime options: ABAP, Java, Node.js, Python
- Integration with external platforms
- Modern development frameworks (CAP, UI5, React, etc.)

### Architecture Patterns
1. **SAP Cloud Application Programming Model (CAP)** - Primary framework for BTP extensions
2. **SAP Fiori Elements on BTP** - UI layer connecting back to S/4HANA
3. **Event-driven extensions** - React to S/4HANA business events via SAP Event Mesh
4. **Workflow extensions** - SAP Build Process Automation for custom workflows
5. **Integration extensions** - SAP Integration Suite for complex integrations

### Communication with S/4HANA
- **OData APIs** (V2 and V4) - Primary integration protocol
- **SOAP APIs** - For legacy integration scenarios
- **RFC/BAPI** (via Cloud Connector) - For private edition / on-premise
- **SAP Event Mesh** - For event-driven patterns
- **IDocs** - For document exchange scenarios

### When to Use Side-by-Side
- Complex extensions requiring multiple technology stacks
- Extensions needing AI/ML capabilities
- Multi-system integration scenarios
- Extensions requiring independent scaling
- Partner SaaS solutions
- When the required functionality cannot be achieved on-stack

---

## 8. BAdI Patterns in S/4HANA Cloud

### What is a BAdI?
Business Add-In (BAdI) is an object-oriented enhancement option that enables implementing enhancements to standard SAP applications without modifying the original code.

### BAdI Types in S/4HANA Cloud

#### Cloud BAdIs (Released BAdIs)
- Released with formal stability contracts
- Available for both Key User and Developer Extensibility
- Found in SAP Business Accelerator Hub under "Developer Extensibility > Business Add-Ins"
- Listed under "Released Objects" in ADT project explorer

#### Key User BAdIs
- Implemented via "Custom Logic" Fiori app
- Limited ABAP syntax (restricted to whitelisted statements)
- Before Save / After Save event hooks
- No ADT required

#### Developer BAdIs
- Implemented via ADT (Eclipse) using ABAP Cloud
- Full ABAP Cloud syntax available
- More powerful than Key User BAdIs
- Requires ABAP development skills

### Implementation Steps (Developer Extensibility)

1. **Find Available BAdIs**:
   - SAP Business Accelerator Hub: S/4HANA Cloud > Developer Extensibility > Business Add-Ins
   - ADT: Released Objects > Enhancement Spots
   - Extensibility Wizard (since 2408 release)

2. **Create BAdI Enhancement Implementation**:
   - In ADT: Select package > New > Other ABAP Object > BAdI Enhancement Implementation
   - Select the released Enhancement Spot
   - Select the specific BAdI definition

3. **Implement the BAdI Class**:
   - A skeleton class is generated automatically
   - Implement the interface methods
   - Use only ABAP Cloud-compatible syntax
   - Use released APIs only

4. **Activate and Test**:
   - Format, save, and activate the implementation
   - Use ABAP Debugger for step-through debugging
   - Test in the associated business process

### Common BAdI Use Cases
- **Purchase Requisition Checks**: Validate PR data before creation
- **Purchase Order Validation**: Custom validation logic for PO processing
- **Field Control**: Control field visibility/editability dynamically
- **Determination**: Auto-fill fields based on business rules
- **Authorization Checks**: Custom authorization logic
- **Output Management**: Custom output formats/channels

### BAdI Best Practices
- Always check SAP Business Accelerator Hub for available BAdIs before custom development
- Use filter values to control when your BAdI implementation executes
- Keep BAdI logic lightweight - avoid heavy processing
- Handle exceptions properly - unhandled exceptions can break standard processes
- Document your BAdI implementations thoroughly
- Test BAdI implementations with various data scenarios including edge cases

---

## 9. Custom Business Objects (CBO)

### Overview
Custom Business Objects (CBOs) allow creating new business entities through the Fiori app "Custom Business Objects". They generate database tables, CDS views, OData services, and maintenance UIs.

### Creation Process

1. **Open "Custom Business Objects" App** (F2626 on Fiori Launchpad)
2. **Define Structure**:
   - Name the business object
   - Define fields (name, type, length, description)
   - Create node hierarchies (header/item patterns)
3. **Enable Generation Options**:
   - Check "UI Generation" - generates maintenance UI (similar to SM30 in classic ABAP)
   - Check "Service Generation" - generates OData service for API access
4. **Publish** - Triggers generation of:
   - Database table(s)
   - CDS view(s)
   - OData service
   - Fiori maintenance UI (if selected)
5. **Add Custom Logic**:
   - Determination: Auto-populate fields on create/edit/save
   - Validation: Check data integrity, display error messages
   - Available events: Before Save, After Modification

### Making CBO Accessible
- Use "Custom Catalog Extensions" app to assign generated UI to a business catalog
- Assign the business catalog to a business role
- Users with the role can access the CBO maintenance UI on Fiori Launchpad

### CBO Capabilities
- Master data management (custom reference data)
- Simple transactional data capture
- Configuration tables
- Extension tables linked to standard objects via custom fields
- Basic workflow-like processing via status fields and validation

### CBO Limitations
- Limited ABAP syntax in custom logic (restricted subset)
- No complex business logic (for that, use Developer Extensibility)
- No direct integration with standard transaction processing
- Field types limited to predefined set
- No custom authorization objects
- Performance considerations for large data volumes

---

## 10. ABAP Cloud Development Model & RAP

### ABAP Cloud Overview
ABAP Cloud is the ABAP development model for building clean core compliant, cloud-ready business apps, services, and extensions. It works on:
- SAP BTP ABAP Environment
- SAP S/4HANA Cloud (all editions)
- SAP S/4HANA On-Premise (since 2022)

### Three-Layer RAP Architecture

#### Layer 1: CDS Data Model
- Core Data Services (CDS) views form the data foundation
- Define data model, associations, annotations
- Projection views for consumption-specific views
- Extension-enabled via C0 release contract

#### Layer 2: Behavior Definition (BDL)
- Uses Behavior Definition Language (BDL)
- Defines transactional behavior: CRUD, actions, determinations, validations
- Specifies implementation type (managed/unmanaged)
- Defines draft handling, locking, authorization

#### Layer 3: Service Definition & Binding
- Service Definition: Exposes CDS entities as service
- Service Binding: Binds service to protocol (OData V2, V4, Web API)
- OData V4 is the default standard since 2025

### RAP Implementation Types

#### Managed Implementation (Greenfield)
- **Best for**: New applications, clean core development
- **Framework handles**: CRUD operations, locking, draft handling, transaction buffer
- **Developer focus**: Business logic (validations, determinations, actions)
- **Minimal code needed**: A ready-to-run BO can work without ABAP behavior pool
- **Database**: Automatic persistence management

#### Unmanaged Implementation (Brownfield)
- **Best for**: Wrapping existing logic, legacy integration
- **Developer handles**: All transactional logic manually in ABAP classes
- **Use cases**: Integrating BAPIs, function modules, existing business logic
- **Full control**: Over database operations and transaction handling

#### Managed with Unmanaged Save (Hybrid)
- **Best for**: New BO needing legacy persistence
- **Framework handles**: Buffer management, draft, locking
- **Developer handles**: Save/persistence logic only
- **Balance**: Agility of managed + customization for complex save scenarios

### Key RAP Concepts

#### Determinations
- Automatically triggered logic that fills/calculates field values
- Triggered on: Create, Update, specific field changes
- Example: Auto-calculate total price from quantity * unit price

#### Validations
- Check business rules before save
- Can raise error/warning messages
- Example: Validate that order date is not in the past

#### Actions
- Custom operations beyond standard CRUD
- Can be instance-bound or static
- Example: "Approve", "Reject", "Submit" actions

#### Draft Handling
- Enables save-as-draft capability
- Framework manages draft tables automatically (managed scenario)
- Essential for Fiori elements apps

#### Authorization Control
- Global authorization: Who can access the BO at all?
- Instance authorization: Who can access specific instances?
- Integrated with PFCG-based authorization

### Entity Manipulation Language (EML)
- ABAP language extension for RAP BO consumption
- Syntax: `MODIFY ENTITIES OF`, `READ ENTITIES OF`
- Type-safe, strongly typed operations
- Used both in BO implementation and BO consumers

---

## 11. S/4HANA Cloud Public vs Private vs On-Premise

### Extensibility Comparison Matrix

| Feature | Public Cloud | Private Cloud | On-Premise |
|---------|-------------|---------------|------------|
| **Key User Extensibility** | Full | Full | Full |
| **Developer Extensibility (ABAP Cloud)** | Full (Embedded Steampunk) | Full (since 2022) | Full (since 2022) |
| **Classic ABAP Extensibility** | NOT available | Available | Available |
| **SAP GUI Access** | NOT available | Full access | Full access |
| **Source Code Modifications** | NOT possible | Possible (but discouraged) | Possible (but discouraged) |
| **Classic Enhancements (CMOD/SMOD)** | NOT available | Available | Available |
| **Implicit Enhancements** | NOT available | Available (Level D) | Available (Level D) |
| **Side-by-Side (BTP)** | Full | Full | Full |
| **BAdIs (Cloud)** | Released cloud BAdIs only | Released cloud BAdIs + classic | All |
| **BAdIs (Classic)** | NOT available | Available | Available |
| **Custom Tables (SE11)** | NOT available | Available | Available |
| **Custom Tables (ABAP Cloud)** | Via CBO or ADT | Via CBO or ADT | Via CBO or ADT |
| **IMG Customizing** | Limited (Self-Service Config) | Full IMG | Full IMG |
| **Partner Add-ons** | Cloud-ready add-ons only | Classic + cloud add-ons | All add-ons |
| **Upgrade Control** | SAP-managed (quarterly) | Customer-managed | Customer-managed |

### Public Cloud Edition Specifics
- Most restrictive but most upgrade-safe
- Extensions only via SAP-approved frameworks
- Quarterly automatic updates by SAP
- Self-Service Configuration replaces IMG for business configuration
- Two extensibility categories: In-App + Side-by-Side (+ Developer via Embedded Steampunk)
- Functional scope is narrower than Private/On-Premise

### Private Cloud Edition Specifics
- Full backend access via SAP GUI
- Can use classic ABAP alongside ABAP Cloud
- Customer controls upgrade timing
- Supports partner add-ons (classic and cloud-ready)
- Structural changes to SAP source code possible
- Clean core strongly recommended but not enforced

### On-Premise Specifics
- Broadest extensibility capabilities
- Full customization including kernel-level
- Customer manages all infrastructure
- No forced upgrade cycle
- Clean core principles applicable but optional
- Full IMG configuration

---

## 12. Cloudification Repository & Released APIs

### What is the Cloudification Repository?
A repository containing the list of all released APIs of SAP Cloud ERP, plus non-released objects with their successor specifications. Maintained as JSON files on GitHub.

### GitHub Repository
- **URL**: github.com/SAP/abap-atc-cr-cv-s4hc
- Contains JSON/CSV files with released objects per release
- Free to use without registration
- Updated with each S/4HANA Cloud release

### Contents
- Released API list (objects with C0/C1/C2/C3 contracts)
- Classic API list (Level B objects - documented but without formal contract)
- Non-released objects with successor mappings
- Object types: Classes, Interfaces, CDS Views, Function Modules, BAdIs, Data Elements, Domains, Table Types

### Usage in ATC
- Used as content for the ATC check "Usage of Released APIs (Cloudification Repository)"
- Configure the URL pointing to current APIs in ATC settings
- ATC test validates custom code against the released object list
- Findings show which objects are released, classic, or non-released

### Successor Object Mapping
- For non-released objects, the repository specifies replacement/successor objects
- Critical for custom code migration from classic ABAP to ABAP Cloud
- Example: Classic table MARA -> Released CDS view I_Product
- "Include released successor objects from cloudification repo in your ABAP custom code migration" is a documented migration pattern

### SAP Business Accelerator Hub
- Official portal for discovering released APIs
- URL: api.sap.com
- Browse by: Package > S/4HANA Cloud > API type
- API types: OData V2/V4, SOAP, REST, Events, BAdIs
- Each API includes documentation, try-out capability, and release information

---

## 13. ATC Cloud Readiness Checks

### ABAP Test Cockpit (ATC) Overview
ATC is the primary tool for analyzing custom code regarding cloud readiness and clean core compliance.

### Key ATC Check Variants
1. **Usage of Released APIs (Cloudification Repository)** - Checks against released API list
2. **S/4HANA Readiness Check** - Validates custom code for S/4HANA migration
3. **ABAP Cloud Readiness Check** - Validates ABAP Cloud compliance

### Setup & Configuration
- Can run locally or remotely
- Remote ATC: Central ATC system checks code in satellite systems
- Requires SSL setup for accessing Git-hosted cloudification repository
- SAP Note 2436688: Recommended notes for S/4HANA custom code checks in ATC

### Common ATC Findings

#### Critical Findings
- Use of non-released SAP objects (no release contract)
- Direct access to SAP internal tables
- Use of restricted ABAP statements
- Modifications to SAP standard code

#### Warning Findings
- Use of classic APIs (Level B) that have released successors
- Deprecated function module calls
- Non-optimal coding patterns

### Quick Fixes
- ATC findings marked with yellow lightbulb have automated Quick Fixes
- Quick Fixes can automatically replace non-released objects with released successors
- Available in ADT problems view

### Troubleshooting Common Issues

1. **Check Failures**: Click "Check Failures" number to see categories and missing prerequisites
2. **Namespace Scope Issues**: ATC uses "check scope" (customer namespace list) to determine relevant findings; modified/enhanced SAP objects may need scope adjustment
3. **SSL Handshake Failed**: Ensure SSL certificates configured for accessing GitHub from S/4 system
4. **Missing Prerequisites**: Apply all recent notes from SAP Note 2436688 before troubleshooting
5. **False Positives**: Some findings may be for SAP-owned namespace objects in scope - verify ownership

---

## 14. CDS View Extensions

### Extending Released CDS Views
- A CDS view extension adds elements to an existing released CDS view without modifying it
- Requires the base CDS view to have C0 (Developer Extensibility) release contract
- Uses `extend view` syntax in ABAP Cloud

### Creating Custom CDS Views
- Built via "Custom CDS Views" Fiori app (Key User) or ADT (Developer)
- Can consume released CDS views (C1 contract minimum)
- Read access only (no transactional CDS via custom CDS view app)
- Key User app provides guided creation

### CDS View Extension Syntax (Developer Extensibility)
```sql
extend view entity I_SalesOrder with ZZ_SalesOrderExtension {
  // Add fields from underlying data source
  salesorder.ZZ_CustomField as CustomField
}
```

### Restrictions
- Can only add fields from data sources already used by the base view
- Cannot add new associations to unrelated entities
- Cannot change existing field logic or annotations (in C0 extensions)
- Non-public SAP CDS views need wrapping and releasing by customer before ABAP Cloud consumption

---

## 15. SAP Extensibility Wizard

### Overview
A guided tool available since S/4HANA Cloud Public Edition 2408 that simplifies creating extensions while preserving clean core principles.

### Key Features
- Consolidates on-stack and side-by-side extension options in a single wizard
- Context-aware: Understands which S/4HANA application it was started from
- Filters extension points (APIs, Events) based on business context
- Guides users through the complete extension creation process

### Extension Points Covered
- Released APIs for the business context
- Available BAdIs
- Business Events
- Custom Fields
- Custom Logic

### Integration with SAP Build
- The wizard integrates with SAP Build for low-code/no-code extension creation
- Available in SAP Build for creating both simple and complex extensions

---

## 16. Best Practices

### Architecture Best Practices
1. **API-First**: Always check for a released API before building custom
2. **Prefer Standard**: Question every deviation from SAP standard
3. **Right Extensibility Type**: Match extensibility type to use case complexity
4. **Decouple When Possible**: Use side-by-side for complex scenarios
5. **Design for Upgrade**: Every extension must survive quarterly updates

### Development Best Practices
1. **Use ABAP Cloud from Day 1**: Even on Private/On-Premise
2. **Released Objects Only**: Never access SAP internal objects in new code
3. **RAP for Transactional Apps**: Use RAP managed implementation for new apps
4. **CDS-Based Data Model**: Always use CDS views, not direct table access
5. **Proper Error Handling**: Use RAP message handling, not classic SY-SUBRC
6. **Unit Testing**: Write ABAP unit tests for all custom logic
7. **Naming Conventions**: Use Z*/Y* namespace, consistent naming patterns

### Governance Best Practices
1. **Extension Registry**: Maintain catalog of all extensions with clean core level
2. **Approval Process**: Require governance sign-off for Level B+ extensions
3. **Remediation Roadmap**: Plan migration path for Level C/D extensions
4. **Regular ATC Scans**: Run cloud readiness checks with every transport
5. **Documentation**: Document business justification for every extension
6. **KPIs**: Track clean core compliance metrics (% Level A, trend over time)

### Performance Best Practices
1. **Lightweight BAdIs**: Keep BAdI logic minimal, avoid heavy DB operations
2. **Efficient CDS**: Use proper associations, avoid unnecessary joins
3. **Buffer Properly**: Use RAP transactional buffer, avoid repeated DB reads
4. **Async Where Possible**: Use background processing for heavy operations

---

## 17. Anti-Patterns

### Level D Anti-Patterns (Never Do)
1. **SAP Source Code Modifications** - Direct changes to SAP code objects
2. **Implicit Enhancements** - Enhancement points without explicit spots
3. **Direct SAP Table Writes** - INSERT/UPDATE/DELETE on SAP tables
4. **Kernel Modifications** - Changes to ABAP kernel behavior
5. **Hardcoded SAP Object Names** - Using internal SAP object names that may change

### Level C Anti-Patterns (Avoid / Remediate)
1. **Non-Released Table Access** - SELECT from SAP internal tables
2. **Non-Released FM Calls** - Calling undocumented function modules
3. **Internal CDS View Consumption** - Using CDS views without release contracts
4. **Assumption of Internal Structure** - Coding based on SAP internal data structure knowledge

### Architecture Anti-Patterns
1. **Over-Extension** - Building extensions for functionality that exists in standard
2. **Monolithic Extensions** - Single large extension instead of modular approach
3. **Tight Coupling** - Extensions deeply coupled to SAP internal processing
4. **No Documentation** - Extensions without business justification or technical docs
5. **Copy-Paste from Classic** - Porting classic ABAP code without adapting to ABAP Cloud patterns
6. **Ignoring Events** - Building polling integrations instead of using SAP Event Mesh
7. **UI-Layer Workarounds** - Implementing business logic in UI layer instead of proper BAdI/RAP

### Common Mistakes
1. Using classic ABAP patterns in ABAP Cloud (e.g., CALL FUNCTION instead of released class methods)
2. Not checking SAP Business Accelerator Hub before building custom APIs
3. Building custom reports when standard analytical CDS views exist
4. Creating custom fields via developer extensibility when Key User extensibility suffices
5. Not implementing draft handling in Fiori elements apps
6. Ignoring authorization control in RAP BOs
7. Not running ATC checks before transport release

---

## 18. Common Errors & Troubleshooting

### ABAP Cloud Syntax Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Object X is not released" | Using non-released SAP object | Find released successor in Cloudification Repository |
| "Statement X not allowed in ABAP Cloud" | Using restricted ABAP statement | Replace with ABAP Cloud compatible alternative |
| "COMMIT WORK not allowed" | Using COMMIT in restricted context | Let RAP framework handle commits |
| "Access to SAP table X not permitted" | Direct SELECT from non-released table | Use released CDS view instead |
| "Classic exception handling" | Using CATCH SYSTEM-EXCEPTIONS | Use TRY-CATCH with class-based exceptions |

### BAdI Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Enhancement Spot not released" | Trying to implement non-released BAdI | Use only released Enhancement Spots from Business Accelerator Hub |
| "BAdI implementation not active" | Implementation not activated | Activate in ADT and check filter conditions |
| "Runtime error in BAdI" | Unhandled exception in BAdI code | Add proper exception handling; BAdI must not crash standard process |
| "BAdI not triggered" | Filter conditions not matching | Verify filter values match runtime context |

### ATC Check Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "SSL Handshake Failed" | Missing SSL certificate | Install SSL certificate for GitHub access |
| "Check Failures" | Missing prerequisites | Apply SAP Note 2436688 recommended notes |
| "SAP-owned namespace in scope" | Scope configuration issue | Adjust ATC check scope to customer namespaces only |
| "No findings generated" | Wrong check variant | Ensure correct cloud readiness check variant selected |

### RAP Development Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "Entity not bound" | Missing service binding | Create and activate service binding for protocol |
| "Draft table not found" | Draft not configured properly | Add `with draft;` to behavior definition and generate draft tables |
| "Authorization failed" | Missing authorization control | Implement authorization control in behavior definition |
| "Determination loop" | Determination triggers itself | Use proper trigger conditions, avoid circular field dependencies |
| "Validation timing" | Validation at wrong point | Check validation trigger (ON SAVE vs ON MODIFY) |

---

## 19. 2025-2026 Timeline & Roadmap

### 2025 Key Events
- **August 2025**: Four-level (A-D) Clean Core maturity framework formalized
- **August 2025**: Updated ABAP Extensibility Guide published
- **Q4 2025**: Next major ABAP extensibility guide update (ABAP custom code management tools + ABAP AI capabilities)
- **December 2025**: SAP announced final transition period for Compatibility Packs

### 2026 Key Events
- **May 2026**: Cutoff for S/4HANA Compatibility Packs (final transition deadline)
- **2026 Ongoing**: AI-driven Custom Code Migration capability expanding substantially
- **2026 Ongoing**: Enhanced changelog for SAP objects (Level C risk mitigation)

### Strategic Direction
- SAP pushing all customers toward Level A compliance
- AI-assisted code migration tools becoming primary remediation mechanism
- ABAP Cloud as THE development model for all SAP ABAP development
- Side-by-side on BTP as primary innovation platform
- RAP as the mandatory framework for new transactional applications
- Increasing automation in extension governance and compliance checking

---

## Key Reference URLs

### Official SAP Resources
- **ABAP Extensibility Guide**: community.sap.com/t5/technology-blog-posts-by-sap/abap-extensibility-guide-clean-core-for-sap-s-4hana-cloud-august-2025/ba-p/14175399
- **SAP Business Accelerator Hub**: api.sap.com
- **SAP Extensibility Explorer**: extensibilityexplorer.cfapps.eu10.hana.ondemand.com
- **ABAP Cloud FAQ**: pages.community.sap.com/topics/abap/abap-cloud-faq
- **RAP Community Page**: pages.community.sap.com/topics/abap/rap
- **Clean Core White Paper**: sap.com/documents/2024/09/20aece06-d87e-0010-bca6-c68f7e60039b.html

### GitHub Resources
- **ATC Cloud Readiness Check Variants**: github.com/SAP/abap-atc-cr-cv-s4hc
- **RAP Workshop Materials**: github.com/SAP-samples/abap-platform-rap-workshops
- **ABAP Cheat Sheets**: github.com/SAP-samples/abap-cheat-sheets
- **RAP120 (Fiori + Joule)**: github.com/SAP-samples/abap-platform-rap120

### SAP Learning
- **Clean Core Extensibility Course**: learning.sap.com/courses/practicing-clean-core-extensibility-for-sap-s-4hana-cloud
- **RAP100 Tutorial**: developers.sap.com/mission.sap-fiori-abap-rap100.html
- **BAdI Implementation Tutorial**: developers.sap.com/tutorials/abap-s4hcloud-procurement-po-debugging.html

### Community & Third-Party
- **Clean Core 4-Level Model**: sachinartani.com/blog/clean-core-extensibility-4-level-model
- **A-D Extensibility Model Explained**: avotechs.com/blog/what-is-clean-core-a-d-extensibility-model/
- **Release Contracts (C0-C3)**: community.sap.com/t5/technology-blog-posts-by-members/understanding-release-contracts-c0-c3-in-s-4hana-repository-objects/ba-p/14223288
- **SAP Clean Core Best Practices**: blog.sap-press.com/sap-s4hana-clean-core-principles-benefits-and-best-practices
