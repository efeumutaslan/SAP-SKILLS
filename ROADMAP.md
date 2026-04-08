# SAP Skills Development Roadmap

> **Current:** v1.0 — 23 skills, 33 references, 19 templates, 4 scripts, 4 MCP configs
> **License:** MIT (competitive advantage over secondsky's GPL-3.0)
> **Repo:** https://github.com/efeumutaslan/SAP-SKILLS.git

---

## Phase 1: Foundation Hardening (v1.1) — Priority: HIGH

**Goal:** Make existing 23 skills production-grade with measurable quality.

### 1.1 Eval Framework
- [ ] Create `evals/` directory with test scenarios per skill
- [ ] Each eval: user prompt → expected behavior → pass/fail criteria
- [ ] Minimum 5 evals per skill (115 total)
- [ ] Example: "User says 'create a RAP BO with draft'" → skill should produce BDEF with draft actions, draft table, Prepare action
- [ ] Automate with a runner script (`scripts/run-evals.sh`)

### 1.2 Skill Line Budget Audit
- [ ] Audit all 23 SKILL.md files against 500-line max
- [ ] Move overflow content to `references/` (progressive disclosure)
- [ ] Ensure every skill follows: Quick Start → Core Concepts → Patterns → Errors → Tips → Gotchas

### 1.3 Template Completeness
- [ ] Every skill must have at least 1 template in `templates/`
- [ ] Missing templates: sap-ariba, sap-cloud-alm, sap-security-authorization, sap-testing-quality, sap-integration-suite-advanced
- [ ] Templates must be copy-paste ready with `{{PLACEHOLDER}}` markers

### 1.4 Validation Scripts
- [ ] Current: 4 scripts (abap-cloud, clean-core, cap-project, rap-bo)
- [ ] Add: `validate-skill.sh` — lints SKILL.md structure (frontmatter, required sections, line count)
- [ ] Add: `validate-all.sh` — runs all validators, outputs summary report
- [ ] Integrate into CI with GitHub Actions

---

## Phase 2: Plugin Architecture (v2.0) — Priority: HIGH

**Goal:** Enable marketplace distribution via `/plugin marketplace add`.

### 2.1 Plugin Structure Conversion
```
.claude-plugin/
  marketplace.json          # Plugin metadata for marketplace
sap-skills/                 # Plugin root
  skills/                   # All 23+ skills
  agents/                   # 4 agents
  commands/                 # 5 commands
  hooks/                    # 3 hooks
  mcp-configs/              # 4 configs
```

### 2.2 marketplace.json
```json
{
  "name": "sap-skills",
  "version": "2.0.0",
  "description": "Comprehensive SAP development skills for Claude Code",
  "author": "efeumutaslan",
  "license": "MIT",
  "skills": 23,
  "agents": 4,
  "commands": 5,
  "hooks": 3
}
```

### 2.3 Installation Experience
```bash
# Target UX:
/plugin marketplace add https://github.com/efeumutaslan/SAP-SKILLS.git

# Or from marketplace registry:
/plugin marketplace add sap-skills
```

### 2.4 Modular Install
- [ ] Allow installing individual skill groups (e.g., only ABAP skills, only BTP skills)
- [ ] Tags in marketplace.json: `["abap", "btp", "fiori", "integration", "analytics"]`

---

## Phase 3: New Skills (v2.1–2.5) — Priority: MEDIUM

**Goal:** Expand from 23 to 35+ skills covering full SAP landscape.

### Wave 1 — Analytics & Data (v2.1)
| Skill | Description |
|-------|-------------|
| `sap-bw4hana` | BW/4HANA modeling, ADSOs, composite providers, BW queries |
| `sap-datasphere` | Datasphere spaces, replication flows, analytic models |
| `sap-analytics-cloud` | SAC stories, planning models, smart predict |

### Wave 2 — Commerce & CX (v2.2)
| Skill | Description |
|-------|-------------|
| `sap-commerce-cloud` | SAP Commerce (Hybris) — extensions, ImpEx, Solr, OCC API |
| `sap-emarsys` | Marketing automation, segments, campaigns, Web Extend |
| `sap-cdp` | Customer Data Platform — profiles, audiences, integrations |

### Wave 3 — HR & Finance (v2.3)
| Skill | Description |
|-------|-------------|
| `sap-concur` | Concur API, expense reports, travel workflows |
| `sap-s4-finance` | S/4HANA Finance — ACDOCA, universal journal, financial close |
| `sap-payroll` | SF Employee Central Payroll, off-cycle payroll, retro calculations |

### Wave 4 — Industry & Specialized (v2.4)
| Skill | Description |
|-------|-------------|
| `sap-industry-cloud` | Vertical industry solutions (automotive, retail, utilities) |
| `sap-mdg` | Master Data Governance — data models, rules, workflows |
| `sap-grc` | Governance, Risk, Compliance — SoD analysis, risk rules |

### Wave 5 — Advanced Platform (v2.5)
| Skill | Description |
|-------|-------------|
| `sap-workflow-management` | BTP Workflow Management, task UIs, workflow definitions |
| `sap-document-management` | DMS, CMIS, SAP Document Center |
| `sap-forms` | Adobe Forms, SAP Forms by Adobe, print forms |

### Prioritization Criteria
1. **Community demand** — GitHub issues, SAP Community questions
2. **MCP server availability** — Skills with paired MCP tools are more valuable
3. **Uniqueness** — No existing coverage in other skill repos

---

## Phase 4: Marketplace Submission (v2.0+) — Priority: MEDIUM

**Goal:** Get SAP-SKILLS listed in major skill directories.

### 4.1 Targets
| Platform | URL | Status | Strategy |
|----------|-----|--------|----------|
| awesome-claude-skills | travisvn/awesome-claude-skills (9.7K★) | No SAP skills | Submit PR — first SAP entry |
| awesome-agent-skills | VoltAgent/awesome-agent-skills (680+) | No SAP skills | Submit PR — first SAP entry |
| aitmpl.com | aitmpl.com | 1000+ skills, no SAP | Submit via their process |
| SkillsMP | skillsmp.io | Marketplace | Register when plugin format ready |

### 4.2 Submission Checklist
- [ ] README.md with badges (skill count, license, last verified)
- [ ] Demo GIF/video showing skill activation
- [ ] Contributing guide (CONTRIBUTING.md)
- [ ] Changelog (CHANGELOG.md)
- [ ] GitHub topics: `claude-code`, `agent-skills`, `sap`, `abap`, `btp`, `fiori`

---

## Phase 5: Community & Maintenance (Ongoing) — Priority: MEDIUM

### 5.1 Version Cadence
| Cycle | Frequency | Focus |
|-------|-----------|-------|
| Patch (x.x.1) | Monthly | Error fixes, typos, SAP version updates |
| Minor (x.1.0) | Quarterly | New skills, new references, eval updates |
| Major (x.0.0) | Bi-annually | Architecture changes, breaking changes |

### 5.2 SAP Release Alignment
- [ ] Track SAP QRC (Quarterly Release Cycle) — update skills within 4 weeks of each QRC
- [ ] Key dates: QRC1 (Feb), QRC2 (May), QRC3 (Aug), QRC4 (Nov)
- [ ] Monitor: SAP Road Map Explorer, SAP Community release notes
- [ ] Update `last_verified` in frontmatter after each review

### 5.3 Community Building
- [ ] CONTRIBUTING.md — How to add a skill, review process, style guide
- [ ] GitHub Discussions — Enable for Q&A and skill requests
- [ ] SAP Community blog post announcing the project
- [ ] Template for community-contributed skills (`templates/SKILL-TEMPLATE.md`)

### 5.4 Quality Monitoring
- [ ] GitHub Actions CI: validate all SKILL.md on PR
- [ ] Monthly: run evals, update pass rates
- [ ] Quarterly: review analytics (if marketplace provides), prune unused skills
- [ ] Track GitHub stars, forks, issues as health metrics

---

## Phase 6: Advanced Features (v3.0) — Priority: LOW

### 6.1 LSP Integration
- [ ] CAP CDS Language Server integration (like secondsky)
- [ ] ABAP Language Server integration
- [ ] Provides real-time validation beyond static skills

### 6.2 Interactive Tutorials
- [ ] `tutorials/` directory with step-by-step guided exercises
- [ ] Example: "Build your first RAP BO in 30 minutes"
- [ ] Integrated with MCP servers for live system interaction

### 6.3 Skill Composition
- [ ] Meta-skills that orchestrate multiple skills for complex scenarios
- [ ] Example: "Full-stack BTP app" = CAP + HANA + Fiori + Security + DevOps
- [ ] Agent-driven workflow: plan → scaffold → implement → test → deploy

### 6.4 Localization
- [ ] Turkish translations for descriptions and Quick Start sections
- [ ] German translations (largest SAP market)
- [ ] Localized error catalogs

---

## Milestone Summary

| Version | Target | Key Deliverable |
|---------|--------|-----------------|
| v1.1 | Apr 2026 | Eval framework + validation CI |
| v2.0 | May 2026 | Plugin architecture + marketplace.json |
| v2.1 | Jun 2026 | +3 analytics skills, marketplace submissions |
| v2.2 | Jul 2026 | +3 commerce skills |
| v2.3 | Aug 2026 | +3 HR/finance skills (align with QRC3) |
| v2.4 | Oct 2026 | +3 industry skills |
| v2.5 | Nov 2026 | +3 platform skills (align with QRC4) |
| v3.0 | Q1 2027 | LSP integration, tutorials, composition |

---

## Success Metrics

| Metric | Current | v2.0 Target | v3.0 Target |
|--------|---------|-------------|-------------|
| Skills | 23 | 23 (hardened) | 35+ |
| Evals | 0 | 115+ | 175+ |
| Eval pass rate | — | >80% | >90% |
| GitHub stars | 0 | 50+ | 200+ |
| Marketplace listings | 0 | 2+ | 4+ |
| Contributors | 1 | 3+ | 10+ |
| MCP server pairings | 6 | 10+ | 15+ |
