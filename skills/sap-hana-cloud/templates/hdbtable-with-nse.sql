-- HDI Table Template with NSE (Native Storage Extension)
-- Replace: {{TABLE_NAME}}, {{SCHEMA}}, columns as needed

COLUMN TABLE "{{TABLE_NAME}}" (
  -- Primary key
  "ID"              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Business fields
  "ENTITY_ID"       NVARCHAR(20) NOT NULL,
  "DESCRIPTION"     NVARCHAR(255),
  "STATUS"          NVARCHAR(1) DEFAULT 'A',
  "AMOUNT"          DECIMAL(15,2),
  "CURRENCY"        NVARCHAR(3) DEFAULT 'EUR',
  "CATEGORY"        NVARCHAR(50),

  -- Timestamps
  "CREATED_AT"      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CHANGED_AT"      TIMESTAMP,
  "CREATED_BY"      NVARCHAR(100),

  -- Large/archival fields (page loadable = NSE warm storage)
  "DETAILS"         NCLOB,
  "ATTACHMENT"      BLOB
)
-- Partition strategy: recent data in-memory, old data on disk (NSE)
WITH PARAMETERS (
  'PARTITION_SPEC' = 'RANGE ("CREATED_AT")
    (PARTITION VALUE <= ''2024-12-31'' PAGE LOADABLE,
     PARTITION VALUE <= ''2025-12-31'' COLUMN LOADABLE,
     PARTITION OTHERS COLUMN LOADABLE)'
);

-- Indexes
CREATE INDEX "IDX_{{TABLE_NAME}}_ENTITY" ON "{{TABLE_NAME}}" ("ENTITY_ID");
CREATE INDEX "IDX_{{TABLE_NAME}}_STATUS" ON "{{TABLE_NAME}}" ("STATUS", "CREATED_AT");
