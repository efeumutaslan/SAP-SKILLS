# Contributing to SAP Skills

Thank you for contributing! This guide explains how to add or improve SAP skills.

## Adding a New Skill

### 1. Create the Directory
```bash
mkdir -p skills/your-skill-name/{references,templates}
```
The directory name must match the `name` field in SKILL.md (lowercase, hyphens only).

### 2. Write SKILL.md

Follow the [Agent Skills Specification](https://agentskills.io/specification):

```yaml
---
name: your-skill-name
description: |
  Brief description of what this skill does and when to use it.
  Use when: [list of trigger scenarios].
license: MIT
metadata:
  author: your-name
  version: "1.0.0"
---
```

### 3. Required Sections in SKILL.md

Every skill must include:

1. **Related Skills** — Cross-references to complementary skills
2. **Quick Start** — Essential info readable in 30 seconds
3. **Core Concepts** — Key terminology and architecture
4. **Common Patterns** — Copy-paste ready code examples
5. **Error Catalog** — At least 10 common errors with solutions
6. **Performance Tips** — Optimization guidance

### 4. Quality Checklist

- [ ] SKILL.md is under 500 lines
- [ ] Description includes trigger keywords
- [ ] Code examples are syntactically correct
- [ ] Templates use `{{PLACEHOLDER}}` markers
- [ ] References are standalone files (loadable on demand)
- [ ] No sensitive data (passwords, API keys, hostnames)

### 5. Submit a Pull Request

- One skill per PR (unless tightly coupled)
- Include a brief description of the SAP area covered
- Reference any SAP documentation sources used

## Improving Existing Skills

- Fix errors, add missing patterns, update for new SAP versions
- Add reference docs for uncovered sub-topics
- Add templates for common development scenarios
- Keep changes focused — don't restructure unrelated sections

## Style Guide

- **Language**: English primary, Turkish inline where helpful
- **SAP Terms**: Use official casing (BAdI, CDS, OData, ABAP, Fiori)
- **Code Comments**: Minimal, explanatory, no filler
- **Markdown**: Use tables for structured data, code blocks for examples
