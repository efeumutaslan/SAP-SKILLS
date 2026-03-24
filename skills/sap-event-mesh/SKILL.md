---
name: sap-event-mesh
description: |
  SAP Event Mesh and SAP Integration Suite Advanced Event Mesh skill. Use when: implementing
  event-driven architectures on SAP BTP, publishing/consuming events between SAP and non-SAP
  systems, working with SAP Event Mesh service, Advanced Event Mesh (Solace-based), CloudEvents
  specification, S/4HANA business events, webhook subscriptions, message queues/topics, or
  building event-driven microservices with CAP. Covers event broker setup, topic design, and
  integration patterns.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Event Mesh & Event-Driven Architecture

## Related Skills
- `sap-kyma-runtime` — Event-driven Functions on Kyma consuming Event Mesh
- `sap-s4hana-extensibility` — S/4HANA business events as event sources
- `sap-build-process-automation` — Trigger workflows from events

## Quick Start

**Choose your event broker:**

| Broker | Use Case | Protocol | Scale |
|--------|----------|----------|-------|
| **SAP Event Mesh** | BTP-native events, simple pub/sub | AMQP 1.0, REST, MQTT | Standard workloads |
| **Advanced Event Mesh** | Enterprise event mesh, multi-cloud | AMQP, MQTT, REST, SMF, JMS, WebSocket | High throughput, global |

**Minimal CAP event producer:**

```javascript
// srv/order-service.js
const cds = require('@sap/cds');

module.exports = class OrderService extends cds.ApplicationService {
  async init() {
    this.after('CREATE', 'Orders', async (order) => {
      const msg = await cds.connect.to('messaging');
      await msg.emit('sap/sales/order/created/v1', {
        orderId: order.ID,
        customer: order.customer_ID,
        total: order.total
      });
    });
    await super.init();
  }
};
```

## Core Concepts

### CloudEvents Specification
SAP Event Mesh uses CloudEvents 1.0 standard:

```json
{
  "specversion": "1.0",
  "type": "sap.s4.beh.salesorder.v1.SalesOrder.Created.v1",
  "source": "/default/sap.s4.beh/S4HANA_CLD",
  "id": "a1b2c3d4-5678-90ab-cdef",
  "time": "2026-03-24T10:00:00Z",
  "datacontenttype": "application/json",
  "data": {
    "SalesOrder": "1000001",
    "SalesOrganization": "1010",
    "SoldToParty": "CUST001"
  }
}
```

### Topic Naming Convention
```
{namespace}/{business-object}/{event-type}/{version}

Examples:
sap.s4.beh/salesorder/created/v1
sap.s4.beh/businesspartner/changed/v1
custom/myapp/order/fulfilled/v1
```

**Hierarchy rules:**
- Use `/` as level separator
- Wildcards: `+` (single level), `*` (multi-level) — for subscriptions only
- Subscription example: `sap/s4/beh/+/created/v1` matches all "created" events

### Event Mesh Architecture
```
S/4HANA ──► Enterprise Messaging ──► Event Mesh ──► Consumers
                                       │
BTP Apps ──► CAP Messaging ────────────┘      ┌── BTP App (webhook)
                                               ├── Kyma Function
External ──► REST/AMQP ───────────────────────├── Integration Flow
                                               └── Queue → Worker
```

### Queue vs. Topic
| Aspect | Topic | Queue |
|--------|-------|-------|
| Delivery | Pub/sub (1-to-many) | Point-to-point (1-to-1) |
| Persistence | Not persistent | Messages persisted until consumed |
| Pattern | Events, notifications | Task processing, reliable delivery |
| Subscription | Topic filter with wildcards | Direct queue binding |

## Common Patterns

### Pattern 1: Event Mesh Service Instance (BTP)

```json
// mta.yaml resource
{
  "name": "event-mesh",
  "type": "org.cloudfoundry.managed-service",
  "parameters": {
    "service": "enterprise-messaging",
    "service-plan": "default",
    "path": "./event-mesh.json"
  }
}
```

```json
// event-mesh.json
{
  "emname": "my-app-events",
  "namespace": "custom/myapp",
  "version": "1.0.0",
  "options": {
    "management": true,
    "messagingrest": true,
    "messaging": true
  },
  "rules": {
    "topicRules": {
      "publishFilter": ["${namespace}/order/*"],
      "subscribeFilter": ["${namespace}/order/*", "sap/s4/beh/+/created/v1"]
    },
    "queueRules": {
      "publishFilter": ["${namespace}/*"],
      "subscribeFilter": ["${namespace}/*"]
    }
  }
}
```

### Pattern 2: CAP Event Consumer

```javascript
// srv/event-handler.js
const cds = require('@sap/cds');

module.exports = async (srv) => {
  const msg = await cds.connect.to('messaging');

  // Subscribe to S/4HANA business partner events
  msg.on('sap/s4/beh/businesspartner/changed/v1', async (event) => {
    const { BusinessPartner } = event.data;
    console.log(`BP changed: ${BusinessPartner}`);

    // Sync to local replica
    const { BusinessPartners } = srv.entities;
    const bpData = await fetchBPFromS4(BusinessPartner);
    await cds.run(UPSERT.into(BusinessPartners).entries(bpData));
  });

  // Subscribe with wildcard
  msg.on('custom/myapp/order/+/v1', async (event) => {
    console.log(`Order event: ${event.headers.type}`, event.data);
  });
};
```

```json
// package.json — messaging config
{
  "cds": {
    "requires": {
      "messaging": {
        "kind": "enterprise-messaging",
        "format": "cloudevents",
        "publishPrefix": "custom/myapp/",
        "subscribePrefix": "custom/myapp/"
      }
    }
  }
}
```

### Pattern 3: REST API — Publish Event

```python
import requests
import json

def publish_event(token_url, client_id, client_secret, em_url, topic, data):
    """Publish event via Event Mesh REST API."""
    # Get OAuth token
    token_resp = requests.post(
        f"{token_url}/oauth/token?grant_type=client_credentials",
        auth=(client_id, client_secret)
    )
    token = token_resp.json()["access_token"]

    # Publish
    encoded_topic = topic.replace("/", "%2F")
    resp = requests.post(
        f"{em_url}/messagingrest/v1/topics/{encoded_topic}/messages",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/cloudevents+json",
            "x-qos": "1"  # 0=at-most-once, 1=at-least-once
        },
        json={
            "specversion": "1.0",
            "type": topic,
            "source": "/custom/myapp",
            "id": str(__import__('uuid').uuid4()),
            "data": data
        }
    )
    resp.raise_for_status()
    return resp.status_code
```

### Pattern 4: Queue Subscription with Webhook

```python
def create_queue_subscription(token, em_url, queue_name, topic_filter):
    """Create queue and bind topic subscription."""
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    # Create queue
    requests.put(
        f"{em_url}/messagingrest/v1/queues/{queue_name}",
        headers=headers,
        json={"messageTimeToLive": 86400, "maxQueueSizeInBytes": 10485760}
    )

    # Subscribe queue to topic
    encoded_topic = topic_filter.replace("/", "%2F")
    requests.put(
        f"{em_url}/messagingrest/v1/queues/{queue_name}/subscriptions/{encoded_topic}",
        headers=headers
    )
```

### Pattern 5: S/4HANA Business Event Configuration

**Enable events in S/4HANA Cloud:**
1. App: "Enterprise Event Enablement" → Maintain channel binding
2. Create channel: type = "SAP Event Mesh", connection = destination to Event Mesh
3. Select event topics: `sap.s4.beh.salesorder.v1.SalesOrder.Created.v1`
4. Activate channel

**S/4HANA On-Premise (via Integration Suite):**
```
S/4HANA → AIF/IDoc → SAP Integration Suite → Event Mesh
```

### Pattern 6: Dead Letter Queue Pattern

```javascript
// Handle failed messages with retry
const msg = await cds.connect.to('messaging');

msg.on('custom/myapp/order/created/v1', async (event) => {
  try {
    await processOrder(event.data);
  } catch (err) {
    const retryCount = (event.headers['x-retry-count'] || 0) + 1;
    if (retryCount <= 3) {
      await msg.emit('custom/myapp/order/created/retry/v1', {
        ...event.data,
        _retryCount: retryCount,
        _originalError: err.message
      });
    } else {
      await msg.emit('custom/myapp/dlq/order/v1', {
        ...event.data,
        _error: err.message,
        _failedAt: new Date().toISOString()
      });
    }
  }
});
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `403` | Publish not allowed | Topic not in `publishFilter` | Update `event-mesh.json` rules |
| `403` | Subscribe not allowed | Topic not in `subscribeFilter` | Update subscribe filter rules |
| `404` | Queue not found | Queue deleted or not created | Create queue before consuming |
| `409` | Queue already exists | Duplicate creation attempt | Use PUT (idempotent) instead of POST |
| `413` | Message too large | Exceeds max message size (1 MB default) | Reduce payload; use reference pattern (send URL) |
| `429` | Rate limit exceeded | Too many requests per second | Implement backoff; upgrade service plan |
| `500` | Broker unavailable | Event Mesh service issue | Check BTP system status; retry with backoff |
| Connection refused | AMQP connection failed | Wrong endpoint or credentials | Verify service key `messaging` array endpoints |
| No messages | Consumer gets nothing | Topic filter mismatch | Check wildcard syntax; verify namespace prefix |
| Duplicate events | Same event processed twice | At-least-once QoS | Implement idempotent consumer (check event ID) |

## Performance Tips

1. **Use QoS 0 for non-critical events** — At-most-once is faster; use QoS 1 only for business-critical events
2. **Batch publishing** — Group multiple events per HTTP request where API supports it
3. **Partition queues** — Use multiple queues for parallel consumption of high-volume topics
4. **Message TTL** — Set appropriate `messageTimeToLive` to prevent queue overflow
5. **Payload size** — Keep events small (<10 KB); reference large data via URL/ID
6. **AMQP over REST** — Use AMQP protocol for high-throughput; REST for low-volume/webhook
7. **Consumer acknowledgment** — Acknowledge messages promptly; long processing delays redelivery
8. **Namespace isolation** — Separate namespaces per application; avoid cross-app topic pollution

## Gotchas

- **Topic encoding**: Forward slashes in topic names must be URL-encoded (`%2F`) in REST API paths
- **Namespace prefix**: All topics must match namespace defined in service instance; mismatches silently fail
- **Event ordering**: Event Mesh does NOT guarantee message ordering — design consumers to be order-independent
- **Duplicate delivery**: At-least-once means duplicates are possible — always implement idempotent processing
- **Service plan limits**: `default` plan has message size and throughput limits; check plan quotas
- **S/4HANA events**: Business events must be explicitly enabled per tenant; they're not on by default
