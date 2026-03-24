# SAP Skills Project

## About
Comprehensive SAP skill collection for Claude Code. Skills follow the Agent Skills Specification (agentskills.io).

## Conventions
- Skills are in `skills/<skill-name>/SKILL.md` format
- SKILL.md: YAML frontmatter + Markdown body, max 500 lines
- Reference docs go in `references/`, templates in `templates/`
- Primary language: English. Turkish support via inline translations where helpful.
- SAP terminology uses official SAP naming (e.g., "BAdI" not "BADI", "CDS" not "Cds")
- Code examples must be syntactically correct and follow SAP best practices
- Keep comments minimal and explanatory — no filler

## Quality Rules
- Every SKILL.md must have: Quick Start, Core Concepts, Common Patterns, Error Catalog, Performance Tips
- Reference files should be standalone and loadable on demand
- Templates must be copy-paste ready with clear placeholder markers (e.g., `{{ENTITY_NAME}}`)
- Cross-reference related skills using their exact directory names
