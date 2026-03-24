# SAP Skills Ekosistem Durum Raporu

**Tarih:** 2026-03-23
**Amac:** Mevcut SAP skills reposunun eksikliklerini tespit etmek ve kapsamli bir SAP skills seti olusturmak.

---

## 1. Mevcut Durum: secondsky/sap-skills (GitHub)

**Repo:** https://github.com/secondsky/sap-skills
**Versiyon:** 2.1.7 | **Lisans:** GPL-3.0 | **Stars:** 157
**Toplam Skill:** 32 plugin

### Mevcut Skill Listesi

| # | Skill | Kategori | Derinlik | Ref. Dosya |
|---|-------|----------|----------|------------|
| 1 | sap-abap | ABAP | Derin | 28 |
| 2 | sap-abap-cds | ABAP | Derin | Templates |
| 3 | sap-ai-core | AI | Iyi | 8 |
| 4 | sap-cloud-sdk-ai | AI | Hafif | - |
| 5 | sap-btp-best-practices | BTP | Cok Derin | 8 (~94K satir) |
| 6 | sap-btp-build-work-zone-advanced | BTP | Iyi | 13 |
| 7 | sap-btp-business-application-studio | BTP | Iyi | 7 |
| 8 | sap-btp-cias | BTP | Iyi | 7 |
| 9 | sap-btp-cloud-logging | BTP | Iyi | 7 |
| 10 | sap-btp-cloud-platform | BTP | Iyi | - |
| 11 | sap-btp-cloud-transport-management | BTP | Iyi | - |
| 12 | sap-btp-connectivity | BTP | Iyi | - |
| 13 | sap-btp-developer-guide | BTP | Iyi | - |
| 14 | sap-btp-integration-suite | BTP | Derin | - |
| 15 | sap-btp-intelligent-situation-automation | BTP | Hafif | - |
| 16 | sap-btp-job-scheduling | BTP | Hafif | - |
| 17 | sap-btp-master-data-integration | BTP | Hafif | - |
| 18 | sap-btp-service-manager | BTP | Hafif | - |
| 19 | sap-cap-capire | CAP | Cok Derin | 22 + 4 agent + MCP |
| 20 | sap-datasphere | Data | Iyi | 3 agent |
| 21 | sap-sac-custom-widget | Data | Iyi | - |
| 22 | sap-sac-planning | Data | Iyi | - |
| 23 | sap-sac-scripting | Data | Cok Derin | 63 ref + 56 template |
| 24 | sap-sqlscript | Data | Iyi | - |
| 25 | sap-hana-cli | HANA | Iyi | 91 komut |
| 26 | sap-hana-cloud-data-intelligence | HANA | Hafif | - |
| 27 | sap-hana-ml | HANA | Hafif | - |
| 28 | sap-api-style | Tooling | Iyi | 8 |
| 29 | sap-fiori-tools | UI | Iyi | - |
| 30 | sapui5 | UI | Iyi | - |
| 31 | sapui5-cli | UI | Hafif | - |
| 32 | sapui5-linter | UI | Hafif | - |

### Plugin Yapisi (secondsky format)
```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json          # Manifest
  skills/<skill-name>/
    SKILL.md             # Ana bilgi dosyasi
    README.md            # Okunabilir ozet
    references/          # Detayli referans dokumanlari
    templates/           # Kod/config sablonlari
  agents/                # Opsiyonel: otonom agent tanimlari
  commands/              # Opsiyonel: slash komutlari
  hooks/                 # Opsiyonel: validasyon hook'lari
```

---

## 2. Diger Skill Repolari

### weiserman/rap-skills (Stars: 12)
- **Odak:** Yalnizca SAP RAP gelistirme
- **5 Skill:** rap-generator, rap-cds, rap-behavior, rap-testing, rap-troubleshoot
- **Ozellik:** Branch-per-target (BTP/S4HANA Cloud/On-Prem icin farkli branch'ler)
- **Bagimlilik:** Vibing Steampunk (VSP) MCP server
- **Guc:** Cevre-duyarli (strict(2) vs strict(1) vs none)

### KEIDAI-TechTime/sap-claude-skills (Stars: 0)
- SAP add-on gelistirme skill paketleri (Japonca)

### mfigueir/sap-skills-power (Stars: 0)
- Kiro IDE icin SAP skill paketi

### one-kash/sap-odata-explorer (Stars: 17)
- SAP OData endpoint kesfetme skill'i

---

## 3. Ekosistem: SAP MCP Serverlari (59 repo)

**Master Liste:** https://github.com/marianfoo/sap-ai-mcp-servers

### Resmi SAP MCP Serverlari (5)
| Server | Amac |
|--------|------|
| CAP MCP Server | CAP gelistirme |
| SAP Fiori MCP Server | Fiori app olusturma |
| UI5 MCP Server | UI5 gelistirme |
| UI5 Web Components MCP | UI5 Web Components |
| SAP MDK MCP Server | Mobil gelistirme |

### Topluluk MCP Serverlari (Onemli Olanlar)
| Server | Amac | Stars |
|--------|------|-------|
| Vibing Steampunk | ABAP ADT-to-MCP koprusu | 218 |
| mcp-sap-docs | SAP dokumantasyon arama | 145 |
| odata-mcp-proxy | OData/REST → MCP | 8 |
| SAP OData to MCP (BTP) | SAP OData → MCP | 114 |
| OData MCP Go Bridge | OData v2/v4 → MCP | 119 |
| mcp-abap-abap-adt-api | ABAP ADT API | 102 |
| mcp-sap-gui | SAP GUI otomasyon | 95 |
| ABAP MCP Server SDK | ABAP'da MCP server yaz | 59 |
| SAP Datasphere MCP | 45 tool, OAuth | 14 |
| SAP Security MCP | 17 guvenlik araci | 1 |
| SAP Notes MCP | SAP Note arama | 42 |
| HANA MCP Server | HANA veritabani | 39 |
| HANA Developer CLI MCP | 150+ HANA CLI araci | - |
| SAP SuccessFactors MCP | 43 HR araci | 3 |
| SAP Cloudification Repo MCP | Released API kontrol | 18 |

---

## 4. Skill Standardi: Agent Skills Specification

**Kaynak:** https://agentskills.io/specification

```markdown
skill-name/
  SKILL.md          # Zorunlu: YAML frontmatter + markdown talimatlar
  scripts/          # Opsiyonel: calistirilabilir kod
  references/       # Opsiyonel: detayli dokumanlar
  assets/           # Opsiyonel: sablonlar, kaynaklar
```

**SKILL.md Formati:**
```yaml
---
name: skill-name              # Zorunlu. Max 64 char
description: Ne yapar...      # Zorunlu. Max 1024 char
license: Apache-2.0           # Opsiyonel
compatibility: Requires X     # Opsiyonel
metadata:
  author: org-name
  version: "1.0"
allowed-tools: Bash(git:*) Read  # Opsiyonel
---
# Talimatlar burada
```

**aitmpl.com'daki Diger Skill Kategorileri:**
- Agents (otonom uzmanlar)
- Commands (slash komutlari)
- Settings (konfigurasyonlar)
- Hooks (otomasyon tetikleyiciler)
- MCPs (MCP entegrasyonlari)
