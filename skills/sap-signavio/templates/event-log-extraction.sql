-- SAP Signavio Process Mining — Event Log Extraction Template
-- Replace: {{SOURCE_TABLE}}, {{CASE_ID}}, {{ACTIVITY}}, {{TIMESTAMP}}
-- Target format: Case ID | Activity | Timestamp | (optional dimensions)

-- ============================================================
-- Purchase-to-Pay (P2P) Event Log from S/4HANA
-- ============================================================
SELECT
  ekko.ebeln                        AS case_id,        -- PO Number
  CASE
    WHEN eban.banfn IS NOT NULL AND ekko.ebeln IS NULL
      THEN 'Purchase Requisition Created'
    WHEN ekko.aedat = ekko.bedat
      THEN 'Purchase Order Created'
    WHEN ekbe.belnr IS NOT NULL AND ekbe.bewtp = 'E'
      THEN 'Goods Receipt Posted'
    WHEN ekbe.belnr IS NOT NULL AND ekbe.bewtp = 'Q'
      THEN 'Invoice Receipt Verified'
    WHEN bseg.augbl IS NOT NULL
      THEN 'Payment Executed'
  END                                AS activity,
  COALESCE(ekko.aedat, eban.badat)  AS event_timestamp,
  ekko.bukrs                        AS company_code,
  ekko.ekorg                        AS purchasing_org,
  ekko.lifnr                        AS vendor,
  ekko.bsart                        AS document_type,
  ekpo.netwr                        AS net_value,
  ekpo.waers                        AS currency
FROM ekko
  LEFT JOIN ekpo ON ekko.ebeln = ekpo.ebeln
  LEFT JOIN eban ON ekpo.banfn = eban.banfn AND ekpo.bnfpo = eban.bnfpo
  LEFT JOIN ekbe ON ekpo.ebeln = ekbe.ebeln AND ekpo.ebelp = ekbe.ebelp
  LEFT JOIN bseg ON ekbe.belnr = bseg.belnr AND ekbe.gjahr = bseg.gjahr
WHERE ekko.aedat >= '{{START_DATE}}'
  AND ekko.aedat <= '{{END_DATE}}'
ORDER BY case_id, event_timestamp;

-- ============================================================
-- Order-to-Cash (O2C) Event Log from S/4HANA
-- ============================================================
SELECT
  vbak.vbeln                        AS case_id,        -- Sales Order
  CASE
    WHEN vbak.audat IS NOT NULL AND likp.vbeln IS NULL
      THEN 'Sales Order Created'
    WHEN likp.wadat_ist IS NOT NULL
      THEN 'Delivery Completed'
    WHEN vbrk.fkdat IS NOT NULL
      THEN 'Billing Document Created'
    WHEN bsad.augdt IS NOT NULL
      THEN 'Payment Received'
  END                                AS activity,
  COALESCE(vbak.erdat, likp.erdat, vbrk.erdat) AS event_timestamp,
  vbak.vkorg                        AS sales_org,
  vbak.kunnr                        AS customer,
  vbak.auart                        AS order_type,
  vbap.netwr                        AS net_value
FROM vbak
  LEFT JOIN vbap ON vbak.vbeln = vbap.vbeln
  LEFT JOIN vbfa ON vbak.vbeln = vbfa.vbelv
  LEFT JOIN likp ON vbfa.vbeln = likp.vbeln AND vbfa.vbtyp_n = 'J'
  LEFT JOIN vbrk ON vbfa.vbeln = vbrk.vbeln AND vbfa.vbtyp_n = 'M'
  LEFT JOIN bsad ON vbrk.vbeln = bsad.vbeln
WHERE vbak.erdat >= '{{START_DATE}}'
  AND vbak.erdat <= '{{END_DATE}}'
ORDER BY case_id, event_timestamp;

-- ============================================================
-- CSV Export Format (for Signavio import)
-- ============================================================
-- Required columns: Case ID, Activity, Start Timestamp
-- Optional: End Timestamp, Resource, Cost, any dimension
-- Date format: YYYY-MM-DD HH:MM:SS or ISO 8601
-- Encoding: UTF-8
-- Separator: comma or semicolon
