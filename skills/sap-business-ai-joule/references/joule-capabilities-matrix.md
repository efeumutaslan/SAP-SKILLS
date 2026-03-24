# SAP Business AI & Joule — Capabilities Matrix

## Joule Integration Points

| SAP Product | Capability | Example Prompts |
|------------|-----------|-----------------|
| S/4HANA Cloud | Natural language search, guided transactions | "Show overdue invoices over €10K" |
| SuccessFactors | Employee data queries, goal creation | "Create Q2 goals for my team" |
| Ariba | Requisition creation, spend analysis | "Create a purchase req for 50 laptops" |
| Concur | Expense report assistance | "Summarize my pending expenses" |
| BTP Build Code | Code generation, explanation | "Generate a CDS view for sales orders" |
| Integration Suite | iFlow assistance | "Map field X to field Y" |
| Analytics Cloud | Chart creation, data questions | "Show revenue trend by region" |
| Signavio | Process optimization suggestions | "Identify bottlenecks in P2P" |

## AI Foundation Services (BTP)

| Service | Purpose | API Endpoint |
|---------|---------|-------------|
| AI Core | ML model training & inference | `/v2/lm/deployments` |
| AI Launchpad | ML ops dashboard | UI-based |
| Document Information Extraction | Invoice/PO OCR | `/document-information-extraction/v1/` |
| Data Attribute Recommendation | Master data enrichment | `/data-attribute-recommendation/v2/` |
| Business Entity Recognition | NER for business docs | `/business-entity-recognition/v2/` |
| Translation Hub | Machine translation | `/translation/v2/` |

## AI Core — Generative AI Hub

```python
# Using SAP AI Core SDK for GenAI Hub
from gen_ai_hub.proxy.native.openai import OpenAI

client = OpenAI()

response = client.chat.completions.create(
    model_name="gpt-4",  # or anthropic--claude-3-opus, meta--llama3-70b
    messages=[
        {"role": "system", "content": "You are an SAP expert assistant."},
        {"role": "user", "content": "Explain the ACDOCA table structure"}
    ],
    max_tokens=1000,
    temperature=0.3
)
print(response.choices[0].message.content)
```

## Supported LLMs in AI Core (GenAI Hub)

| Provider | Models | Use Case |
|----------|--------|----------|
| OpenAI | GPT-4, GPT-4 Turbo | Complex reasoning, code generation |
| Anthropic | Claude 3 Opus/Sonnet | Analysis, long documents |
| Meta | Llama 3 70B/8B | Cost-effective tasks |
| Mistral | Mistral Large/Small | European data residency |
| Google | Gemini Pro | Multimodal analysis |
| AWS | Amazon Titan | Embeddings, basic generation |

## Document Information Extraction

```javascript
// Extract invoice fields
const response = await fetch(`${DIE_URL}/document-information-extraction/v1/document/jobs`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'multipart/form-data'
  },
  body: formData  // PDF/image + schema
});

// Schema definition
const schema = {
  "extraction": {
    "headerFields": [
      "documentNumber", "senderName", "senderAddress",
      "grossAmount", "currencyCode", "documentDate"
    ],
    "lineItemFields": [
      "description", "quantity", "unitPrice", "netAmount"
    ]
  }
};
```

## Embedding & RAG Pattern

```python
from gen_ai_hub.proxy.native.openai import OpenAI

client = OpenAI()

# Generate embeddings for SAP docs
embedding = client.embeddings.create(
    input="How to create a purchase order in S/4HANA",
    model_name="text-embedding-ada-002"
)
vector = embedding.data[0].embedding  # Store in HANA Cloud Vector Engine

# HANA Cloud Vector Search
# SELECT * FROM SAP_DOCS
# ORDER BY COSINE_SIMILARITY("EMBEDDING", TO_REAL_VECTOR(?))
# LIMIT 5
```
