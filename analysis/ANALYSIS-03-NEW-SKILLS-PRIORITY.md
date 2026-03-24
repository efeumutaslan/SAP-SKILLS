# Onerilen Yeni Skill Listesi ve Oncelik Siralamasi

**Tarih:** 2026-03-23

---

## Faz 1: KRITIK (Hemen Baslanmali)

Bu skill'ler olmadan SAP gelistirme deneyimi ciddi sekilde eksik kalir.

### SKILL-01: sap-s4hana-extensibility
**Amac:** S/4HANA Cloud ve On-Premise icin extensibility desenleri
**Icerik:**
- Side-by-side extensions (BTP uzerinden)
- In-app extensibility (Key User tools)
- Classic extensibility (BAdI, Enhancement Spots, User Exits)
- S/4HANA Cloud Public vs Private vs On-Premise farklari
- Clean Core prensibi ve uyumluluk kontrolu
- Released API'ler ve Cloudification Repository
- Custom Business Objects (CBO)
- Custom Logic (BRF+, ABAP Cloud)
**Referanslar:** SAP S/4HANA extensibility guide, Clean Core documentation
**MCP Baglantisi:** ClementRingot/sap-released-objects-mcp-server
**Tahmini Buyukluk:** 15+ referans dosya, 5+ template

### SKILL-02: sap-security-authorization
**Amac:** SAP guvenlik, yetkilendirme ve compliance
**Icerik:**
- PFCG rol tasarimi ve best practices
- Authorization objects ve field values
- SU53 analiz desenleri
- SAP_ALL ve kritik yetkilendirme kontrolu
- SoD (Segregation of Duties) matrisi
- SOX compliance kontrolleri
- GDPR veri koruma (ILM, data masking)
- SAP Cloud Identity Services (IAS/IPS)
- Principal Propagation desenleri
- Audit log analizi
**MCP Baglantisi:** SYNTAAI/sap-security-mcp (17 tool)
**Tahmini Buyukluk:** 12+ referans dosya, 8+ template

### SKILL-03: sap-build-process-automation
**Amac:** SAP Build Process Automation ile is sureci otomasyonu
**Icerik:**
- Process builder ile workflow tasarimi
- Decision tables ve business rules
- Automation (RPA bot gelistirme)
- Form tasarimi
- Process visibility & monitoring
- API triggers ve event-based tetikleme
- S/4HANA ve BTP entegrasyonu
- Error handling ve exception management
**Referanslar:** SAP Build Process Automation documentation
**Tahmini Buyukluk:** 10+ referans dosya, 6+ template

### SKILL-04: sap-rap-comprehensive
**Amac:** weiserman/rap-skills'den ilham alarak kapsamli RAP skill
**Icerik:**
- RAP managed vs unmanaged vs managed-with-unmanaged-save
- BDEF (Behavior Definition) tum desenleri
- CDS view entity modelleme (R/C layer)
- Validations, Determinations, Actions, Side Effects
- Draft handling
- Authorization (global + instance)
- EML (Entity Manipulation Language)
- RAP test doubles (CL_BOTD)
- Late numbering, early numbering
- Feature control (static + dynamic)
- Business events
- Extension points
- **Cevre farklari:** BTP Steampunk, S/4HANA Cloud Public, Private, On-Premise
**Referanslar:** weiserman/rap-skills yapisindan ilham
**MCP Baglantisi:** Vibing Steampunk (oisee/vibing-steampunk)
**Tahmini Buyukluk:** 20+ referans dosya, 10+ template, 2+ agent

---

## Faz 2: YUKSEK ONCELIK (1-2 Hafta icinde)

### SKILL-05: sap-hana-cloud
**Amac:** SAP HANA Cloud platform skill (veritabani olarak)
**Icerik:**
- HANA Cloud SQL referansi
- HDI container yonetimi ve deployment
- Calculation Views (graphical + scripted)
- Spatial processing
- Graph engine
- JSON Document Store
- HANA Cloud Vector Engine (embedding/RAG)
- Performance tuning ve explain plan
- Monitoring ve alerting
- Multi-model processing
**MCP Baglantisi:** HatriGt/hana-mcp-server, HANA Developer CLI MCP
**Tahmini Buyukluk:** 15+ referans dosya, 8+ template

### SKILL-06: sap-kyma-runtime
**Amac:** Kyma/Kubernetes-native SAP gelistirme
**Icerik:**
- Kyma Functions (serverless Node.js/Python)
- Kyma Service Mesh (Istio)
- API Rules ve Gateway konfigurasyonu
- Event subscriptions
- Kyma + SAP systems connectivity
- Helm charts ve Kubernetes manifests
- Observability (Prometheus, Grafana, Jaeger)
- Kyma modules yonetimi
**Tahmini Buyukluk:** 10+ referans dosya, 6+ template

### SKILL-07: sap-successfactors
**Amac:** SAP SuccessFactors gelistirme ve entegrasyon
**Icerik:**
- SuccessFactors OData API
- Employee Central entity model
- Recruiting, Learning, Performance modulleri
- MDF (Metadata Framework) ozel alanlari
- Intelligent Services
- Integration Center
- Extension Center
- Event-driven entegrasyon
**MCP Baglantisi:** aiadiguru2025/sf-mcp (43 tool)
**Tahmini Buyukluk:** 12+ referans dosya, 5+ template

### SKILL-08: sap-business-ai-joule
**Amac:** SAP Business AI ve Joule entegrasyonu
**Icerik:**
- Joule capabilities ve activation
- Joule Studio ile MCP server gelistirme
- SAP AI Core generative AI hub (genisletilmis)
- Grounding ve RAG with SAP verileri
- Content filtering ve data masking
- Business AI use case'leri (domain-specific)
- Prompt engineering for SAP context
- Custom AI agent gelistirme (SAP Agent SDK)
**Tahmini Buyukluk:** 10+ referans dosya, 4+ template

### SKILL-09: sap-testing-quality
**Amac:** Cross-cutting SAP test stratejileri
**Icerik:**
- ABAP Unit framework (ileri desenler)
- Test doubles ve mock framework'leri
- RAP test doubles (CL_BOTD)
- CDS test doubles
- wdi5 (WebdriverIO + UI5) end-to-end testing
- OPA5 integration testing
- UIVeri5 visual testing
- API testing (Postman/Newman + SAP)
- Performance testing desenleri
- ATC (ABAP Test Cockpit) kurallari
**Tahmini Buyukluk:** 12+ referans dosya, 8+ template

### SKILL-10: sap-devops-cicd
**Amac:** SAP DevOps ve CI/CD pipeline tasarimi
**Icerik:**
- gCTS (Git-enabled CTS) is akislari
- abapGit kurulum ve kullanim
- BTP CI/CD Service konfigurasyonu
- SAP Cloud Transport Management otomasyonu
- Jenkins + SAP pipeline tasarimi
- GitHub Actions + SAP workflows
- Azure DevOps + SAP entegrasyonu
- Feature branch stratejileri (SAP landscape'e ozel)
- Automated testing in pipelines
**Tahmini Buyukluk:** 10+ referans dosya, 6+ template

---

## Faz 3: ORTA ONCELIK (3-4 Hafta icinde)

### SKILL-11: sap-ariba-procurement
**Amac:** SAP Ariba entegrasyon ve gelistirme
**Icerik:**
- Ariba APIs (cXML, SOAP, REST)
- Procurement workflows
- Supplier management
- Contract management
- Ariba Network entegrasyonu

### SKILL-12: sap-signavio-process
**Amac:** SAP Signavio ile surec modelleme ve analiz
**Icerik:**
- BPMN 2.0 modelleme
- Process mining
- Process Insights
- Process transformation
- SAP S/4HANA surec analizi

### SKILL-13: sap-gui-automation
**Amac:** SAP GUI Scripting ile legacy otomasyon
**Icerik:**
- SAP GUI Scripting (VBScript/Python)
- COM API kullanimi
- Transaction recording ve replay
- Batch input / BDC desenleri
- Error handling
**MCP Baglantisi:** mario-andreschak/mcp-sap-gui

### SKILL-14: sap-event-mesh
**Amac:** Event-driven mimari ve SAP Event Mesh
**Icerik:**
- Event Mesh broker konfigurasyonu
- Queue ve topic yonetimi
- SAP S/4HANA Business Events
- Webhook subscriptions
- Event schema tasarimi
- CloudEvents standardi

### SKILL-15: sap-build-apps
**Amac:** SAP Build Apps low-code gelistirme
**Icerik:**
- Visual app builder
- Data integration
- Logic flows
- Component marketplace
- Deployment

### SKILL-16: sap-cloud-alm
**Amac:** SAP Cloud ALM ile lifecycle management
**Icerik:**
- Implementation tracking
- Operations monitoring
- Change management
- Feature management
**MCP Baglantisi:** gregorwolf/cloud-alm-itsm-mcp

### SKILL-17: sap-mobile-development
**Amac:** SAP mobil uygulama gelistirme
**Icerik:**
- SAP MDK (Mobile Development Kit)
- BTP SDK for iOS/Android
- Offline-capable app desenleri
- Push notification
- SAP Mobile Start entegrasyonu
**MCP Baglantisi:** SAP MDK MCP Server (resmi)

### SKILL-18: sap-migration-modernization
**Amac:** SAP modernizasyon ve gecis projeleri
**Icerik:**
- ECC → S/4HANA migration desenleri
- ABAP Classic → ABAP Cloud gecisi
- Custom Code Migration (ATC kontrolleri)
- SAP Readiness Check
- Clean Core uyumluluk analizi
- Data migration (LTMC, LSMW)
**MCP Baglantisi:** sap-released-objects-mcp-server

---

## Faz 4: MEVCUT SKILL IYILESTIRMELERI

### ENHANCE-01: sap-abap (mevcut) → Derinlestirme
- ABAP Cloud vs Classic net ayrim
- AMDP detayli referans
- ABAP for HANA optimizasyon
- abapGit is akislari
- Released API awareness

### ENHANCE-02: sap-hana-cli (mevcut) → MCP Entegrasyonu
- HANA Developer CLI MCP baglantisi
- Interactive query desenleri

### ENHANCE-03: sap-cap-capire (mevcut) → CAP MCP Plugin
- Resmi CAP MCP Server entegrasyonu
- CAP + Kyma deployment
- CAP multitenancy ileri

### ENHANCE-04: sap-fiori-tools + sapui5 → Test & Accessibility
- wdi5/OPA5 test entegrasyonu
- Accessibility (WCAG 2.1)
- UI5 TypeScript migration
- UI5 Web Components
- Resmi Fiori MCP ve UI5 MCP entegrasyonu

### ENHANCE-05: sap-btp-integration-suite → Derinlestirme
- Groovy scripting best practices
- API Management ileri
- Edge Integration Cell
- B2B/TPM senaryolari

---

## TOPLAM OZET

| Faz | Yeni Skill | Iyilestirme | Toplam |
|-----|-----------|-------------|--------|
| Faz 1 (Kritik) | 4 skill | - | 4 |
| Faz 2 (Yuksek) | 6 skill | - | 6 |
| Faz 3 (Orta) | 8 skill | - | 8 |
| Faz 4 (Iyilestirme) | - | 5 skill | 5 |
| **TOPLAM** | **18 yeni** | **5 iyilestirme** | **23 is kalemi** |

Mevcut 32 skill + 18 yeni skill = **50 skill** (hedef)
+ 5 iyilestirme = kapsamli SAP gelistirme deneyimi
