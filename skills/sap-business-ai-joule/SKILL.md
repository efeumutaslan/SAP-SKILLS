---
name: sap-business-ai-joule
description: >
  SAP Business AI and Joule copilot development skill. Use when integrating SAP AI Core,
  building GenAI Hub scenarios (GPT-4/Claude/Llama), extending Joule, using HANA Cloud
  vector engine for RAG, or working with Document Information Extraction. If the user
  mentions Joule, SAP AI Core, GenAI Hub, AI Foundation, or RAG with SAP data, use this skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-23"
---

# SAP Business AI & Joule Development

## Related Skills
- `sap-hana-cloud` — Vector engine for embeddings, HANA Cloud as knowledge store
- `sap-rap-comprehensive` — RAP-based data access for grounding AI with SAP data
- `sap-cap-advanced` — CAP MCP plugin for AI-assisted development
- `sap-build-apps` — AI-powered low-code app generation
- `sap-integration-suite-advanced` — AI-assisted mapping in Integration Advisor

## Quick Start

**Choose your AI scenario:**

| Scenario | Service | Entry Point |
|----------|---------|-------------|
| Custom ML model training/serving | AI Core | AI Launchpad → ML Operations |
| LLM orchestration (chat, completion) | Generative AI Hub | AI Core API / orchestration |
| Embed AI in SAP standard apps | Joule | Extension Center / Joule Studio |
| RAG with SAP data | GenAI Hub + HANA Vector | Orchestration service |
| Document extraction | Document Information Extraction | BTP service instance |

**Minimal GenAI Hub call (Python):**

```python
from gen_ai_hub.proxy.core.proxy_clients import get_proxy_client
from gen_ai_hub.proxy.langchain import ChatOpenAI

proxy_client = get_proxy_client('gen-ai-hub')

llm = ChatOpenAI(
    proxy_model_name='gpt-4o',
    proxy_client=proxy_client,
    temperature=0.0
)

response = llm.invoke("Summarize SAP S/4HANA extensibility options")
print(response.content)
```

## Core Concepts

### SAP AI Core Architecture
- **Resource groups**: Isolated execution environments (multi-tenant)
- **Configurations**: Define which model/pipeline + parameters to use
- **Deployments**: Running model inference endpoints
- **Executions**: One-time training or batch jobs
- **Artifacts**: Models, datasets registered in AI Core

### Generative AI Hub
- **Proxy access**: Unified API for multiple LLM providers (OpenAI, Azure OpenAI, Anthropic, Google, AWS Bedrock)
- **Orchestration service**: Chain LLM calls with grounding, content filtering, templating
- **Prompt registry**: Version-controlled prompt templates
- **Content filtering**: Input/output moderation (hate, self-harm, sexual, violence)

### Joule Architecture
- **Joule Foundations**: Core capabilities (NLU, context management, response generation)
- **Joule Skills**: Discrete capabilities mapped to SAP business actions
- **Extension Center**: Register custom skills for Joule
- **Guided answers**: Structured multi-turn flows for complex tasks

### Vector Engine (HANA Cloud)
- Native `REAL_VECTOR` data type (up to 5000 dimensions)
- Distance functions: `COSINE_SIMILARITY`, `L2DISTANCE`, `INNER_PRODUCT`
- HNSW index for approximate nearest neighbor (ANN)
- Integrated with SAP GenAI Hub embedding models

## Common Patterns

### Pattern 1: Orchestration Service — Templating + Grounding + Filtering

```python
from gen_ai_hub.orchestration.models.message import SystemMessage, UserMessage
from gen_ai_hub.orchestration.models.template import Template, TemplateValue
from gen_ai_hub.orchestration.models.llm import LLM
from gen_ai_hub.orchestration import OrchestrationClient

llm = LLM(name="gpt-4o", version="latest", parameters={"max_tokens": 1000, "temperature": 0.2})

template = Template(
    messages=[
        SystemMessage("You are an SAP expert assistant. Answer based on the provided context only."),
        UserMessage("Context: {{?context}}\n\nQuestion: {{?question}}")
    ],
    defaults=[TemplateValue(name="context", value="No context provided")]
)

client = OrchestrationClient(llm=llm, template=template)

response = client.run(
    template_values=[
        TemplateValue(name="context", value="S/4HANA supports tier-1 (key user) and tier-2 (developer) extensibility..."),
        TemplateValue(name="question", value="What extensibility tiers does S/4HANA support?")
    ]
)
print(response.content)
```

### Pattern 2: RAG with HANA Cloud Vector Engine

```python
from gen_ai_hub.proxy.core.proxy_clients import get_proxy_client
from gen_ai_hub.proxy.langchain import OpenAIEmbeddings, ChatOpenAI
from hdbcli import dbapi

proxy_client = get_proxy_client('gen-ai-hub')
embeddings = OpenAIEmbeddings(proxy_model_name='text-embedding-ada-002', proxy_client=proxy_client)

# 1. Embed the query
query = "How do I create a custom CDS view extension?"
query_vector = embeddings.embed_query(query)

# 2. Search HANA Cloud vector store
conn = dbapi.connect(address='<host>', port=443, user='<user>', password='<pwd>', encrypt=True)
cursor = conn.cursor()
cursor.execute("""
    SELECT TOP 5 "CONTENT",
           COSINE_SIMILARITY("EMBEDDING", TO_REAL_VECTOR(?)) AS score
    FROM "KNOWLEDGE_BASE"
    ORDER BY score DESC
""", [str(query_vector)])
chunks = [row[0] for row in cursor.fetchall()]

# 3. Generate answer with context
llm = ChatOpenAI(proxy_model_name='gpt-4o', proxy_client=proxy_client, temperature=0.0)
context = "\n---\n".join(chunks)
response = llm.invoke(f"Context:\n{context}\n\nQuestion: {query}\n\nAnswer based on context only:")
print(response.content)
```

### Pattern 3: Content Filtering Configuration

```python
from gen_ai_hub.orchestration.models.content_filter import ContentFilter, AzureFilterThreshold

input_filter = ContentFilter(
    provider="azure",
    hate=AzureFilterThreshold.ALLOW_SAFE,
    self_harm=AzureFilterThreshold.ALLOW_SAFE,
    sexual=AzureFilterThreshold.ALLOW_SAFE,
    violence=AzureFilterThreshold.ALLOW_SAFE
)

output_filter = ContentFilter(
    provider="azure",
    hate=AzureFilterThreshold.ALLOW_SAFE,
    self_harm=AzureFilterThreshold.ALLOW_SAFE,
    sexual=AzureFilterThreshold.ALLOW_SAFE,
    violence=AzureFilterThreshold.ALLOW_SAFE_LOW
)

client = OrchestrationClient(
    llm=llm,
    template=template,
    input_filter=input_filter,
    output_filter=output_filter
)
```

### Pattern 4: CAP Plugin for AI (Node.js)

```javascript
// package.json — add cap-llm-plugin
// "dependencies": { "@cap-js/hana": "^1", "cap-llm-plugin": "^1" }

// srv/ai-service.js
const cds = require('@sap/cds');

module.exports = class AIService extends cds.ApplicationService {
  async init() {
    this.on('askQuestion', async (req) => {
      const { question } = req.data;
      const vectorPlugin = await cds.connect.to('cap-llm-plugin');

      // RAG: retrieve + generate
      const response = await vectorPlugin.getRagResponse(
        question,
        'KNOWLEDGE_BASE',  // HANA table with embeddings
        'EMBEDDING',        // vector column
        'CONTENT',          // text column
        'text-embedding-ada-002',
        'gpt-4o',
        5  // top-k
      );

      return { answer: response };
    });
    await super.init();
  }
};
```

### Pattern 5: Joule Custom Skill Definition

```json
{
  "name": "lookup-material",
  "description": "Look up material master data by material number or description",
  "parameters": {
    "type": "object",
    "properties": {
      "materialNumber": {
        "type": "string",
        "description": "SAP material number (e.g., MAT-001)"
      },
      "searchTerm": {
        "type": "string",
        "description": "Free text search term for material description"
      }
    }
  },
  "endpoint": {
    "url": "https://<app>.cfapps.<region>.hana.ondemand.com/api/materials/search",
    "method": "POST",
    "authentication": "OAuth2ClientCredentials"
  }
}
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `401 Unauthorized` | `JWT token validation failed` | AI Core service key expired or wrong | Regenerate service key in BTP Cockpit |
| `429 Too Many Requests` | Rate limit exceeded | Too many LLM calls per minute | Implement retry with exponential backoff; check quota |
| `404 Deployment not found` | `No running deployment` | Model not deployed or deployment scaled to 0 | Check AI Launchpad → Deployments; redeploy |
| `VECTOR_DIM_MISMATCH` | `Dimension mismatch` | Query vector dimensions ≠ stored vector dimensions | Ensure same embedding model for indexing and querying |
| `Content filtered` | `Output blocked by content filter` | Response triggered moderation | Adjust filter thresholds or rephrase prompt |
| `RESOURCE_EXHAUSTED` | `Resource group quota exceeded` | Too many concurrent deployments | Delete unused deployments; request quota increase |

## Performance Tips

1. **Batch embeddings** — Embed documents in batches of 100-500; single calls are 10-50x slower
2. **Cache embeddings** — Store in HANA `REAL_VECTOR` column; never re-embed unchanged content
3. **HNSW index** — Create for vector columns with >10K rows: `CREATE HNSW VECTOR INDEX ON "TABLE"("COL")`
4. **Chunk size** — 512-1024 tokens per chunk for RAG; too small loses context, too large dilutes relevance
5. **Streaming** — Use streaming responses for chat UIs to reduce perceived latency
6. **Model selection** — Use smaller models (GPT-4o-mini, Claude Haiku) for classification/extraction; larger for reasoning
7. **Prompt caching** — Orchestration service caches prompt templates; reuse templates with variable substitution
8. **Connection pooling** — Reuse AI Core proxy client instances; don't create per request

## Gotchas

- **Resource group isolation**: Models deployed in one resource group are NOT accessible from another
- **Token limits**: Orchestration service has max token limits per model; check `max_tokens` in deployment config
- **Embedding model consistency**: If you change embedding model, you MUST re-embed all existing documents
- **GenAI Hub model availability**: Not all models available in all regions; check SAP Discovery Center
- **HANA vector index**: HNSW index build is CPU-intensive; schedule during low-usage periods
- **Joule skill registration**: Custom skills require SAP Extension Center access and admin approval
