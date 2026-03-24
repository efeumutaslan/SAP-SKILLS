# Aksiyon Plani ve Yol Haritasi

**Tarih:** 2026-03-23

---

## Genel Yaklasim

1. **Agent Skills Specification** standardina uygun skill'ler olustur (agentskills.io)
2. Her skill icin SKILL.md + references/ + templates/ yapisi kullan
3. MCP server entegrasyonlarini skill icinde tanimla
4. Parca parca calis, her skill bagimsiz test edilebilir olmali
5. secondsky/sap-skills yapisini referans al ama kendi formatimizi olustur

---

## ADIM 1: Proje Altyapisini Kur (Gun 1)

### 1.1 Dizin Yapisi
```
SAP-SKILLS/
├── CLAUDE.md                    # Proje kurallari ve konvansiyonlar
├── README.md                    # Proje tanitimi
├── .mcp.json                    # MCP server konfigurasyonlari
├── .claude/
│   └── settings.local.json      # Claude Code izinleri
├── skills/
│   ├── sap-s4hana-extensibility/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   └── templates/
│   ├── sap-security-authorization/
│   ├── sap-build-process-automation/
│   ├── sap-rap-comprehensive/
│   ├── ... (diger skill'ler)
│   └── _shared/                 # Ortak referanslar (SAP terminoloji, genel best practices)
├── mcp-configs/
│   ├── abap-developer.json      # Profil A
│   ├── fullstack-btp.json       # Profil B
│   ├── consultant.json          # Profil C
│   └── integration-dev.json     # Profil D
├── agents/
│   ├── sap-code-reviewer/       # SAP kod review agent
│   ├── sap-troubleshooter/      # SAP sorun giderme agent
│   └── sap-migration-advisor/   # Gecis danismani agent
├── commands/
│   ├── sap-check-clean-core/    # Clean Core uyumluluk kontrolu
│   ├── sap-generate-rap/        # RAP BO scaffold
│   └── sap-security-audit/      # Guvenlik denetimi
├── hooks/
│   ├── abap-lint/               # ABAP kod kalite kontrolu
│   └── cds-validate/            # CDS syntax dogrulama
└── analysis/                    # Bu analiz dosyalari (referans icin sakla)
    ├── ANALYSIS-01-CURRENT-STATE.md
    ├── ANALYSIS-02-GAP-ANALYSIS.md
    ├── ANALYSIS-03-NEW-SKILLS-PRIORITY.md
    ├── ANALYSIS-04-MCP-INTEGRATION-PLAN.md
    └── ANALYSIS-05-ACTION-PLAN.md
```

### 1.2 CLAUDE.md Olustur
- Proje kurallari
- Skill yazim konvansiyonlari
- SAP terminoloji standartlari
- Kalite kriterleri

---

## ADIM 2: Faz 1 Skill'leri Olustur (Hafta 1)

### 2.1 SKILL-01: sap-s4hana-extensibility
**Is Kalemleri:**
- [ ] SKILL.md yaz (extensibility patterns, clean core, released APIs)
- [ ] references/ klasorune 15+ referans dokuman ekle
- [ ] templates/ klasorune BAdI, CBO, side-by-side extension sablonlari ekle
- [ ] SAP Cloudification Repo MCP entegrasyonunu tanimla

### 2.2 SKILL-02: sap-security-authorization
**Is Kalemleri:**
- [ ] SKILL.md yaz (PFCG, auth objects, SoD, compliance)
- [ ] references/ klasorune 12+ referans ekle
- [ ] templates/ klasorune rol tasarimi, audit report sablonlari ekle
- [ ] SAP Security MCP entegrasyonunu tanimla

### 2.3 SKILL-03: sap-build-process-automation
**Is Kalemleri:**
- [ ] SKILL.md yaz (workflow, rules, RPA, forms)
- [ ] references/ klasorune 10+ referans ekle
- [ ] templates/ klasorune workflow, decision table sablonlari ekle

### 2.4 SKILL-04: sap-rap-comprehensive
**Is Kalemleri:**
- [ ] weiserman/rap-skills'deki 5 skill'i analiz et
- [ ] Tek bir kapsamli SKILL.md olustur (tum cevre varyantlari dahil)
- [ ] references/ klasorune 20+ referans ekle
- [ ] templates/ klasorune BDEF, handler, test sablonlari ekle
- [ ] Vibing Steampunk MCP entegrasyonunu tanimla

---

## ADIM 3: Faz 2 Skill'leri Olustur (Hafta 2)

- SKILL-05: sap-hana-cloud
- SKILL-06: sap-kyma-runtime
- SKILL-07: sap-successfactors
- SKILL-08: sap-business-ai-joule
- SKILL-09: sap-testing-quality
- SKILL-10: sap-devops-cicd

---

## ADIM 4: Faz 3 Skill'leri Olustur (Hafta 3-4)

- SKILL-11 ~ SKILL-18 (8 skill)

---

## ADIM 5: Mevcut Skill Iyilestirmeleri (Hafta 4+)

- ENHANCE-01 ~ ENHANCE-05

---

## ADIM 6: Cross-Cutting Bilesenleri Olustur

### 6.1 Agents (Otonom Uzmanlar)
| Agent | Amac |
|-------|------|
| sap-code-reviewer | ABAP/CDS/UI5 kod inceleme, clean core uyumluluk |
| sap-troubleshooter | Hata analizi, dump okuma, log analizi |
| sap-migration-advisor | ECC→S/4, Classic→Cloud ABAP gecis tavsiyesi |
| sap-performance-analyzer | ABAP/HANA/UI5 performans analizi |

### 6.2 Commands (Slash Komutlari)
| Komut | Amac |
|-------|------|
| /sap-check-clean-core | Kodun Clean Core uyumlulugunu kontrol et |
| /sap-generate-rap | RAP Business Object iskeleti olustur |
| /sap-security-audit | Guvenlik denetim raporu olustur |
| /sap-explain-transaction | SAP tcode acikla ve alternatif oner |
| /sap-migration-check | Custom code migration uyumluluk kontrolu |

### 6.3 Hooks (Otomasyon Tetikleyiciler)
| Hook | Tetikleyici | Amac |
|------|------------|------|
| abap-lint | Dosya kaydetme | ABAP syntax ve kalite kontrolu |
| cds-validate | CDS dosya degisimi | CDS annotation ve syntax dogrulama |
| clean-core-check | Commit oncesi | Released API uyumluluk kontrolu |

---

## KALITE KRITERLERI

Her skill icin asagidaki kontrolleri yap:

### Icerik Kalitesi
- [ ] SKILL.md 5000 token'in altinda (progressive disclosure prensibi)
- [ ] Quick Start bolumu 30 saniyede okunabilir
- [ ] Kod ornekleri calisan, test edilmis ornekler
- [ ] Hata katalogu en az 10 yaygin hata iceriyor
- [ ] Performance tips bolumu var

### Yapi Kalitesi
- [ ] YAML frontmatter standartlara uygun
- [ ] references/ dosyalari konuya gore organize
- [ ] templates/ dosyalari hemen kullanilabilir
- [ ] Cross-referanslar diger skill'lere dogru isaret ediyor

### MCP Entegrasyonu
- [ ] Eslesen MCP server tanimlanmis (varsa)
- [ ] MCP tool'larini kullanan ornek workflow var
- [ ] Kurulum talimatlari acik ve test edilmis

---

## BASARI METRIKLERI

| Metrik | Hedef |
|--------|-------|
| Toplam skill sayisi | 50+ (mevcut 32 + 18 yeni) |
| MCP server entegrasyonu | 20+ server |
| Agent sayisi | 4+ otonom uzman |
| Command sayisi | 5+ slash komutu |
| Referans dosya toplami | 200+ dokuman |
| Template toplami | 100+ sablon |
| Kapsanan SAP modulu | 25+ farkli alan |

---

## SONRAKI ADIM

Bu analiz tamamlandi. Simdi kullaniciyla birlikte karar verilmesi gereken konular:

1. **Hangi faz'dan baslamak istiyorsunuz?**
2. **Skill formati:** secondsky yapisi mi, Agent Skills Spec mi, karma mi?
3. **MCP server kurulumlari:** Hangi profili kullanacaksiniz?
4. **Ozel MCP server gelistirme:** Hangileri icin ozel server yazalim?
5. **Lisans tercihi:** GPL-3.0 (secondsky gibi) mi, Apache-2.0 mi, MIT mi?
