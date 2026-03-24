# SAP MCP Server Catalog (March 2026)

## Official SAP Servers

| Server | Package | Tools | Focus |
|--------|---------|-------|-------|
| **Fiori MCP** | `@sap-ux/fiori-mcp-server` | 6 | App generation, page management, annotations |
| **CAP MCP** | `@cap-js/mcp-server` | 2 | CDS model search, CAP documentation |
| **UI5 MCP** | `@ui5/mcp-server` | 10+ | API reference, linting, TS migration, scaffolding |
| **MDK MCP** | `@sap/mdk-mcp-server` | 5+ | Mobile app generation, schema validation, deploy |

## Community — ABAP/ADT

| Server | Package/Repo | Tools | Focus |
|--------|-------------|-------|-------|
| **Vibing Steampunk** | `oisee/vibing-steampunk` | 41-68 | Full ADT bridge: read/write/debug ABAP |
| **ABAP MCP** | `dhowardb/abap-mcp-server` | 3 | Offline ABAP docs (34 resources, TF-IDF search) |
| **ABAP ADT API** | `mario-andreschak/mcp-abap-abap-adt-api` | varies | ABAP system interaction via ADT APIs |

## Community — Documentation & Knowledge

| Server | Package/Repo | Tools | Focus |
|--------|-------------|-------|-------|
| **SAP Docs** | `marianfoo/mcp-sap-docs` | 7 | Hybrid search (BM25 + semantic), ABAP feature matrix |
| **SAP Notes** | `marianfoo/mcp-sap-notes` | 2 | SAP Note search/retrieval (Playwright + SAP Passport) |

## Community — Data & API

| Server | Package/Repo | Tools | Focus |
|--------|-------------|-------|-------|
| **Datasphere** | `MarioDeFelipe/sap-datasphere-mcp` | 45 | Tenant discovery, analytics, ETL, lineage |
| **OData-to-MCP** | `lemaiwo/btp-sap-odata-to-mcp-server` | varies | OData V2/V4 exposure, BTP Destination Service |
| **CData SAP ERP** | `CDataSoftware/sap-erp-mcp-server-by-cdata` | varies | Natural language SAP ERP queries (JDBC) |
| **CData SAP HANA** | `CDataSoftware/sap-hana-mcp-server-by-cdata` | varies | Natural language HANA queries (JDBC) |
| **HANA MCP** | `HatriGt/hana-mcp-server` | varies | HANA/HANA Cloud integration |

## Community — GUI & Automation

| Server | Package/Repo | Tools | Focus |
|--------|-------------|-------|-------|
| **SAP GUI MCP** | `mario-andreschak/mcp-sap-gui` | 5 | Transaction execution, mouse/keyboard automation |

## Master Registry

- **Source**: [marianfoo/sap-ai-mcp-servers](https://github.com/marianfoo/sap-ai-mcp-servers)
- Comprehensive catalog with comparison tables, license info, maintenance status
- Open to community submissions

## Installation Pattern

```json
// claude_desktop_config.json or .mcp.json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/name"],
      "env": {
        "KEY": "value"
      }
    }
  }
}
```
