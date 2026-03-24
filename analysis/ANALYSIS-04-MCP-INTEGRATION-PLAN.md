# MCP Server Entegrasyon Plani

**Tarih:** 2026-03-23

---

## Strateji

Skill'ler **bilgi ve talimat** saglar, MCP server'lar **canli sistem erisimi** saglar.
En guclu deneyim ikisinin birlestirilmesiyle olusur:
- Skill → "nasil yapilir" bilgisi (SKILL.md + references)
- MCP Server → "canli veri ve islem" yetenegi (tools + resources)

---

## Katman 1: RESMI SAP MCP SERVERLARI (Hemen Entegre Edilmeli)

Bu server'lar SAP tarafindan gelistirildi, uretim kalitesinde ve ucretsiz.

| MCP Server | npm Paketi | Eslesen Skill | Entegrasyon |
|------------|-----------|---------------|-------------|
| **CAP MCP Server** | `@cap-js/mcp-server` | sap-cap-capire | CDS modelleme, servis tanimlama, deployment |
| **SAP Fiori MCP Server** | `@sap-ux/fiori-mcp-server` | sap-fiori-tools | Fiori app olusturma, annotation editing |
| **UI5 MCP Server** | `@niclas/ui5-mcp-server` | sapui5 | UI5 best practices, JS→TS migration |
| **UI5 Web Components MCP** | - | sapui5 (yeni) | Web component API, guidelines |
| **SAP MDK MCP Server** | - | sap-mobile-development (yeni) | Mobil app gelistirme |

### Kurulum Ornegi (.mcp.json)
```json
{
  "mcpServers": {
    "cap-mcp": {
      "command": "npx",
      "args": ["@cap-js/mcp-server"]
    },
    "fiori-mcp": {
      "command": "npx",
      "args": ["@sap-ux/fiori-mcp-server"]
    },
    "ui5-mcp": {
      "command": "npx",
      "args": ["@niclas/ui5-mcp-server"]
    }
  }
}
```

---

## Katman 2: TOPLULUK MCP SERVERLARI - YUKSEK DEGER (1-2 Hafta)

### 2.1 ABAP Sistem Erisimi
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **Vibing Steampunk** | oisee/vibing-steampunk | sap-abap, sap-rap | ADT API: kod okuma/yazma, syntax check, ATC, debug |
| **mcp-abap-abap-adt-api** | mario-andreschak/mcp-abap-abap-adt-api | sap-abap | ABAP ADT islemleri (102 star) |
| **SAP Cloudification Repo** | ClementRingot/sap-released-objects-mcp-server | sap-s4hana, sap-migration | Released API A/B/C/D filtreleme |

### 2.2 Dokumantasyon & Bilgi
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **MCP SAP Docs** | marianfoo/mcp-sap-docs | TUM SKILL'LER | SAP developer docs arama |
| **SAP Notes MCP** | marianfoo/mcp-sap-notes | TUM SKILL'LER | SAP Note ve KBA arama |
| **ABAP MCP Server** | marianfoo/abap-mcp-server | sap-abap | ABAP-odakli dokumanlar |

### 2.3 Veritabani
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **HANA MCP Server** | HatriGt/hana-mcp-server | sap-hana-cloud, sap-sqlscript | HANA sorgulama |
| **HANA Developer CLI MCP** | sap-samples | sap-hana-cli | 150+ CLI araci |

### 2.4 OData / API
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **OData MCP Go Bridge** | oisee/odata_mcp_go | sap-api-style | OData v2/v4 universal bridge |
| **SAP OData to MCP (BTP)** | lemaiwo/btp-sap-odata-to-mcp-server | sap-btp-connectivity | BTP destination uzerinden OData |
| **odata-mcp-proxy** | lemaiwo/odata-mcp-proxy | genel | Config-driven OData→MCP |

---

## Katman 3: UZMAN MCP SERVERLARI (2-4 Hafta)

### 3.1 Guvenlik & Compliance
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **SAP Security MCP** | SYNTAAI/sap-security-mcp | sap-security-authorization | 17 guvenlik araci, SOX/GDPR |

### 3.2 Entegrasyon
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **MCP Integration Suite** | 1nbuc/mcp-integration-suite | sap-btp-integration-suite | CPI islemleri |
| **CPI MCP Server** | vadimklimov/cpi-mcp-server | sap-btp-integration-suite | Go-based CPI |

### 3.3 HR / SuccessFactors
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **SF MCP Server** | aiadiguru2025/sf-mcp | sap-successfactors | 43 HR araci |

### 3.4 Analytics & Data
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **SAP Datasphere MCP** | MarioDeFelipe/sap-datasphere-mcp | sap-datasphere | 45 tool, OAuth |
| **SAP Analytics Cloud MCP** | JumenEngels/sap_analytics_cloud_mcp | sap-sac-scripting | SAC API |

### 3.5 GUI Otomasyon
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **MCP SAP GUI** | mario-andreschak/mcp-sap-gui | sap-gui-automation | SAP GUI otomasyon |

### 3.6 BTP Platform
| MCP Server | Repo | Eslesen Skill | Yetenek |
|------------|------|---------------|---------|
| **BTP MCP Server** | lemaiwo/btp-mcp-server | sap-btp-cloud-platform | BTP Core Services |
| **AI Core MCP Server** | lemaiwo/ai-core-mcp-server | sap-ai-core | AI Core lifecycle |
| **Cloud ALM ITSM MCP** | gregorwolf/cloud-alm-itsm-mcp | sap-cloud-alm | ALM ITSM API |

---

## Onerilen MCP Profilleri

Kullanici senaryolarina gore onceden hazirlanmis MCP konfigurasyonlari:

### Profil A: ABAP Developer
```json
{
  "mcpServers": {
    "vibing-steampunk": { "command": "npx", "args": ["vibing-steampunk"] },
    "sap-docs": { "command": "npx", "args": ["mcp-sap-docs"] },
    "sap-notes": { "command": "npx", "args": ["mcp-sap-notes"] },
    "cloudification": { "command": "npx", "args": ["sap-released-objects-mcp"] }
  }
}
```

### Profil B: Full-Stack BTP Developer
```json
{
  "mcpServers": {
    "cap-mcp": { "command": "npx", "args": ["@cap-js/mcp-server"] },
    "fiori-mcp": { "command": "npx", "args": ["@sap-ux/fiori-mcp-server"] },
    "ui5-mcp": { "command": "npx", "args": ["@niclas/ui5-mcp-server"] },
    "hana-mcp": { "command": "npx", "args": ["hana-mcp-server"] },
    "sap-docs": { "command": "npx", "args": ["mcp-sap-docs"] },
    "btp-mcp": { "command": "npx", "args": ["btp-mcp-server"] }
  }
}
```

### Profil C: SAP Analyst / Consultant
```json
{
  "mcpServers": {
    "sap-docs": { "command": "npx", "args": ["mcp-sap-docs"] },
    "sap-notes": { "command": "npx", "args": ["mcp-sap-notes"] },
    "sap-security": { "command": "npx", "args": ["sap-security-mcp"] },
    "sap-gui": { "command": "npx", "args": ["mcp-sap-gui"] },
    "datasphere": { "command": "npx", "args": ["sap-datasphere-mcp"] }
  }
}
```

### Profil D: Integration Developer
```json
{
  "mcpServers": {
    "integration-suite": { "command": "npx", "args": ["mcp-integration-suite"] },
    "odata-proxy": { "command": "npx", "args": ["odata-mcp-proxy"] },
    "sap-docs": { "command": "npx", "args": ["mcp-sap-docs"] },
    "sf-mcp": { "command": "npx", "args": ["sf-mcp"] }
  }
}
```

---

## Ozel MCP Server Gelistirme Onerileri

Bu alanlarda mevcut MCP server bulunmuyor, ozel gelistirme gerekebilir:

### 1. SAP Build Process Automation MCP
- SBPA API'leri uzerinden workflow tetikleme
- Process instance monitoring
- Decision table yonetimi

### 2. SAP Signavio MCP
- Process modelleri okuma/yazma
- Process mining verileri sorgulama
- Transformation insights

### 3. SAP Ariba MCP
- Procurement workflows
- Supplier data sorgulama
- cXML/SOAP API bridge

### 4. SAP Event Mesh MCP
- Queue/topic yonetimi
- Event subscription
- Business event monitoring

### 5. SAP Kyma MCP
- Function deployment
- API Rule yonetimi
- Event subscription konfigurasyonu
