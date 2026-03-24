# SAP Skills for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/Skills-23-brightgreen.svg)](skills/)
[![Agents](https://img.shields.io/badge/Agents-4-orange.svg)](agents/)
[![Commands](https://img.shields.io/badge/Commands-5-blue.svg)](commands/)
[![MCP Configs](https://img.shields.io/badge/MCP_Configs-4-purple.svg)](mcp-configs/)
[![Agent Skills Spec](https://img.shields.io/badge/Agent_Skills-Spec_1.0-blueviolet.svg)](https://agentskills.io/specification)

A comprehensive collection of SAP development skills for [Claude Code](https://claude.ai/claude-code) and compatible AI coding assistants. Covers S/4HANA, BTP, ABAP, RAP, Fiori, HANA, Security, Integration, and more.

> **TR:** SAP geliştirme için kapsamlı Claude Code skill koleksiyonu. 23 skill, 4 agent, 5 komut, 3 hook ve 4 MCP profili ile S/4HANA, BTP, ABAP, RAP, Fiori, HANA, Güvenlik, Entegrasyon ve daha fazlasını kapsar.

## Quick Start

### Option 1: Clone and Install
```bash
git clone https://github.com/YOUR_USERNAME/sap-skills.git
# Copy desired skills to your project
cp -r sap-skills/skills/sap-rap-comprehensive .claude/skills/
```

### Option 2: Add to Project Skills Directory
```bash
# From your SAP project root
mkdir -p .claude/skills
cp -r path/to/sap-skills/skills/* .claude/skills/
```

### Option 3: Global Installation
```bash
# Available to all your projects
cp -r path/to/sap-skills/skills/* ~/.claude/skills/
```

### Option 4: Use MCP Profile
```bash
# Copy a pre-configured MCP profile for your role
cp sap-skills/mcp-configs/abap-developer.json .mcp.json
# Edit connection details (hostname, credentials)
```

## Available Skills (23)

### Core SAP Development (Phase 1)

| Skill | Domain | Description |
|-------|--------|-------------|
| [sap-s4hana-extensibility](skills/sap-s4hana-extensibility/) | S/4HANA | Extensibility patterns, Clean Core, Released APIs, BAdIs, Key User tools |
| [sap-security-authorization](skills/sap-security-authorization/) | Security | Role design, auth objects, SoD, compliance (SOX/GDPR/ISO 27001) |
| [sap-build-process-automation](skills/sap-build-process-automation/) | Automation | Workflows, business rules, RPA bots, forms, process visibility |
| [sap-rap-comprehensive](skills/sap-rap-comprehensive/) | RAP | Full RAP lifecycle: BDEF, CDS, behavior, testing, draft, authorization |

### High Priority (Phase 2)

| Skill | Domain | Description |
|-------|--------|-------------|
| [sap-hana-cloud](skills/sap-hana-cloud/) | HANA | HDI, SQLScript, calculation views, graph, spatial, vector engine, NSE |
| [sap-kyma-runtime](skills/sap-kyma-runtime/) | Kubernetes | Kyma Functions, API Rules, Helm charts, event subscriptions |
| [sap-successfactors](skills/sap-successfactors/) | HXM | Employee Central, OData API, MDF, Integration/Extension Center |
| [sap-business-ai-joule](skills/sap-business-ai-joule/) | AI | AI Core, Generative AI Hub, Joule skills, RAG, vector engine |
| [sap-testing-quality](skills/sap-testing-quality/) | Testing | ABAP Unit, RAP test doubles, CDS TDF, OPA5, wdi5, ATC |
| [sap-devops-cicd](skills/sap-devops-cicd/) | DevOps | gCTS, abapGit, BTP CI/CD, Jenkins, GitHub Actions, transport mgmt |

### Extended Coverage (Phase 3)

| Skill | Domain | Description |
|-------|--------|-------------|
| [sap-ariba](skills/sap-ariba/) | Procurement | Ariba APIs, cXML, PunchOut, CIG, supplier management |
| [sap-signavio](skills/sap-signavio/) | Process | Process mining, BPMN 2.0, Process Intelligence, KPIs |
| [sap-gui-scripting](skills/sap-gui-scripting/) | Automation | SAP GUI Scripting API, VBScript/Python, batch processing |
| [sap-event-mesh](skills/sap-event-mesh/) | Events | Event-driven architecture, CloudEvents, queues, topics |
| [sap-build-apps](skills/sap-build-apps/) | Low-Code | Visual app builder, data integration, logic flows |
| [sap-cloud-alm](skills/sap-cloud-alm/) | ALM | Health monitoring, RUM, business process monitoring, test mgmt |
| [sap-mobile](skills/sap-mobile/) | Mobile | MDK, BTP SDK iOS/Android, offline store, push notifications |
| [sap-migration](skills/sap-migration/) | Migration | ECC→S/4HANA, LTMC, data mapping, cutover planning |

### Advanced / Enhancement (Phase 4)

| Skill | Domain | Description |
|-------|--------|-------------|
| [sap-abap-advanced](skills/sap-abap-advanced/) | ABAP | ABAP Cloud vs Classic, AMDP, abapGit, Released API wrappers |
| [sap-hana-tools](skills/sap-hana-tools/) | HANA Tools | hdbsql CLI, HDI management, Node.js/Python clients, monitoring |
| [sap-cap-advanced](skills/sap-cap-advanced/) | CAP | Multitenancy, Kyma deploy, remote services, feature toggles |
| [sap-fiori-testing](skills/sap-fiori-testing/) | UI Testing | wdi5, OPA5, WCAG 2.1 accessibility, TypeScript, Web Components |
| [sap-integration-suite-advanced](skills/sap-integration-suite-advanced/) | Integration | Groovy scripting, API Management policies, Edge Cell, B2B/EDI |

## Agents (4)

Autonomous SAP expert agents for specialized tasks:

| Agent | Purpose |
|-------|---------|
| [sap-code-reviewer](agents/sap-code-reviewer/) | ABAP/CDS/UI5 code review, Clean Core compliance check |
| [sap-troubleshooter](agents/sap-troubleshooter/) | Error analysis, dump reading, root cause diagnosis |
| [sap-migration-advisor](agents/sap-migration-advisor/) | ECC→S/4HANA readiness assessment, code analysis |
| [sap-performance-analyzer](agents/sap-performance-analyzer/) | ABAP/HANA/UI5 performance bottleneck identification |

## Commands (5)

Slash commands for common SAP tasks:

| Command | Purpose |
|---------|---------|
| `/sap-check-clean-core` | Scan code for Clean Core compliance violations |
| `/sap-generate-rap` | Generate RAP Business Object scaffold from entity name |
| `/sap-security-audit` | Security vulnerability scan (credentials, auth, injection) |
| `/sap-explain-transaction` | Explain SAP tcode with modern Fiori/API alternatives |
| `/sap-migration-check` | S/4HANA migration readiness scan with effort estimate |

## Hooks (3)

Automatic quality checks:

| Hook | Trigger | Purpose |
|------|---------|---------|
| [abap-lint](hooks/abap-lint/) | File save (*.abap) | ABAP naming, complexity, anti-patterns |
| [cds-validate](hooks/cds-validate/) | File save (*.cds) | CDS annotations, naming, performance warnings |
| [clean-core-check](hooks/clean-core-check/) | Pre-commit | Block non-released API and credential commits |

## MCP Server Profiles

Pre-configured MCP server setups for different SAP developer roles:

| Profile | File | MCP Servers |
|---------|------|-------------|
| ABAP Developer | [abap-developer.json](mcp-configs/abap-developer.json) | Vibing Steampunk, SAP Docs, SAP Notes, Cloudification Repo |
| Full-Stack BTP | [fullstack-btp.json](mcp-configs/fullstack-btp.json) | CAP MCP, Fiori MCP, UI5 MCP, HANA MCP, SAP Docs |
| SAP Consultant | [consultant.json](mcp-configs/consultant.json) | SAP Docs, SAP Notes, Security MCP, SAP GUI, Datasphere |
| Integration Dev | [integration-dev.json](mcp-configs/integration-dev.json) | Integration Suite MCP, OData Proxy, SAP Docs, SF MCP |

## Project Structure

```
sap-skills/
├── CLAUDE.md                       # Project conventions
├── README.md                       # This file
├── LICENSE                         # MIT License
├── .mcp.json                       # Default MCP configuration
├── skills/                         # 23 skill definitions
│   ├── sap-s4hana-extensibility/
│   │   └── SKILL.md
│   ├── sap-rap-comprehensive/
│   ├── sap-abap-advanced/
│   ├── ... (20 more)
│   └── _shared/                    # Common references
├── agents/                         # 4 autonomous agents
│   ├── sap-code-reviewer/
│   ├── sap-troubleshooter/
│   ├── sap-migration-advisor/
│   └── sap-performance-analyzer/
├── commands/                       # 5 slash commands
│   ├── sap-check-clean-core/
│   ├── sap-generate-rap/
│   ├── sap-security-audit/
│   ├── sap-explain-transaction/
│   └── sap-migration-check/
├── hooks/                          # 3 quality hooks
│   ├── abap-lint/
│   ├── cds-validate/
│   └── clean-core-check/
├── mcp-configs/                    # 4 MCP profiles
│   ├── abap-developer.json
│   ├── fullstack-btp.json
│   ├── consultant.json
│   └── integration-dev.json
└── analysis/                       # Research & gap analysis
```

## How Skills Work

Skills follow the [Agent Skills Specification](https://agentskills.io/specification):

1. **Auto-detection**: Each skill has trigger keywords in its description. When you mention "RAP business object" or "HANA calculation view", the relevant skill activates automatically.
2. **Progressive disclosure**: Only the skill's metadata loads at startup (~100 tokens). Full instructions load on activation (<5000 tokens). Reference docs load only when needed.
3. **MCP integration**: Skills reference MCP servers for live SAP system access. The skill provides the "how" knowledge, the MCP server provides the "do" capability.

## Compatibility

| Platform | Status |
|----------|--------|
| Claude Code (CLI) | ✅ Fully supported |
| Claude Code (VS Code) | ✅ Fully supported |
| Cursor | ✅ Compatible (via .cursor/skills/) |
| Codex CLI | ✅ Compatible |
| Gemini CLI | ✅ Compatible |
| Kiro IDE | ✅ Compatible |

## Contributing

Contributions are welcome! To add a new skill:

1. Create a directory under `skills/` matching the skill name
2. Write a `SKILL.md` following the [Agent Skills Specification](https://agentskills.io/specification)
3. Include: Quick Start, Core Concepts, Common Patterns, Error Catalog, Performance Tips
4. Add `references/` and `templates/` as needed
5. Submit a pull request

## Related Resources

| Resource | Description |
|----------|-------------|
| [SAP MCP Servers Master List](https://github.com/marianfoo/sap-ai-mcp-servers) | Curated list of all SAP MCP servers |
| [secondsky/sap-skills](https://github.com/secondsky/sap-skills) | 32 SAP plugins for Claude Code |
| [weiserman/rap-skills](https://github.com/weiserman/rap-skills) | RAP-focused Claude Code skills |
| [Agent Skills Specification](https://agentskills.io/specification) | Official skill format standard |
| [SAP Official MCP Servers](https://github.com/cap-js/mcp-server) | CAP, Fiori, UI5 MCP servers by SAP |

## License

This project is licensed under the [MIT License](LICENSE) — free to use, modify, and distribute.
