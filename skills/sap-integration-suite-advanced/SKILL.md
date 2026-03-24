---
name: sap-integration-suite-advanced
description: |
  Advanced SAP Integration Suite skill. Use when: writing Groovy scripts for iFlows, configuring
  API Management policies (rate limiting, spike arrest, OAuth), deploying Edge Integration Cell,
  building B2B/EDI integrations with Trading Partner Management (TPM), working with SAP Integration
  Advisor, advanced message mapping with XSLT/Groovy, monitoring and alerting, or building
  complex integration scenarios with Content Modifier, Splitter, Aggregator patterns. Extends
  the base sap-btp-integration-suite skill.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# Advanced SAP Integration Suite — Groovy, API Mgmt & Edge

## Related Skills
- `sap-event-mesh` — Event-driven integration patterns
- `sap-s4hana-extensibility` — S/4HANA API consumption via Integration Suite
- `sap-security-authorization` — OAuth/SAML policies in API Management
- `sap-devops-cicd` — Integration content transport and CI/CD

## Quick Start

**Advanced capabilities:**

| Capability | Use Case | Key Feature |
|-----------|----------|-------------|
| **Cloud Integration** | A2A, B2B, cloud-to-on-prem | iFlows, Groovy, mapping |
| **API Management** | API facade, rate limiting, analytics | Policies, Developer Portal |
| **Integration Advisor** | B2B message mapping | MAG (Message Application Group) |
| **Trading Partner Management** | EDI/B2B partner onboarding | AS2, EDIFACT, X12 |
| **Edge Integration Cell** | On-premise/private cloud runtime | Kubernetes-based, hybrid |
| **Open Connectors** | 170+ SaaS connectors | Pre-built adapters |

## Core Concepts

### iFlow Processing Pipeline
```
Sender ──► Sender Adapter ──► Integration Flow ──► Receiver Adapter ──► Receiver
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              Content         Message           Router /
              Modifier        Mapping           Splitter
                    │               │               │
                    ▼               ▼               ▼
              Groovy          XSLT /            Aggregator
              Script          Graphical
```

### API Management Policy Types
| Category | Policy | Purpose |
|----------|--------|---------|
| **Traffic** | Spike Arrest | Prevent traffic spikes |
| **Traffic** | Quota | Limit calls per time period |
| **Traffic** | Concurrent Rate Limit | Max simultaneous connections |
| **Security** | OAuth v2.0 | Token validation |
| **Security** | SAML Assertion | SAML token validation |
| **Security** | Verify API Key | Simple API key auth |
| **Mediation** | JSON to XML | Format conversion |
| **Mediation** | Assign Message | Set headers/variables |
| **Extension** | JavaScript | Custom policy logic |

### Edge Integration Cell Architecture
```
┌─────────────────────────────────────────┐
│  Customer Data Center / Private Cloud    │
│  ┌───────────────────────────────────┐  │
│  │     Edge Integration Cell          │  │
│  │  ┌─────────┐  ┌──────────────┐   │  │
│  │  │ Runtime  │  │ Edge Event   │   │  │
│  │  │ (iFlows) │  │ Broker       │   │  │
│  │  └────┬─────┘  └──────┬───────┘  │  │
│  │       │               │           │  │
│  │  ┌────┴───────────────┴────┐     │  │
│  │  │ Kubernetes (K3s/K8s)    │     │  │
│  │  └─────────────────────────┘     │  │
│  └───────────────┬───────────────────┘  │
│                  │ HTTPS (outbound only) │
└──────────────────┼──────────────────────┘
                   ▼
          SAP Integration Suite
          (Cloud Control Plane)
```

## Common Patterns

### Pattern 1: Groovy Script — JSON Transformation

```groovy
import com.sap.gateway.ip.core.customdev.util.Message
import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def Message processData(Message message) {
    def body = message.getBody(String)
    def json = new JsonSlurper().parseText(body)

    // Transform structure
    def result = json.orders.collect { order ->
        [
            orderNumber: order.id,
            customerName: order.customer?.name ?: 'Unknown',
            totalAmount: order.items?.sum { it.price * it.quantity } ?: 0,
            currency: order.currency ?: 'EUR',
            lineItems: order.items?.collect { item ->
                [
                    materialId: item.productId,
                    description: item.description?.take(40),
                    quantity: item.quantity,
                    unitPrice: item.price
                ]
            } ?: []
        ]
    }

    message.setBody(JsonOutput.toJson([salesOrders: result]))
    message.setHeader('Content-Type', 'application/json')
    message.setProperty('OrderCount', result.size())
    return message
}
```

### Pattern 2: Groovy Script — Error Handling & Logging

```groovy
import com.sap.gateway.ip.core.customdev.util.Message
import org.apache.camel.Exchange

def Message processData(Message message) {
    def log = messageLogFactory.getMessageLog(message)
    def props = message.getProperties()

    try {
        def body = message.getBody(String)

        // Validate input
        if (!body || body.trim().isEmpty()) {
            throw new IllegalArgumentException("Empty message body")
        }

        // Log for monitoring (appears in Message Processing Log)
        log?.addAttachmentAsString('InputPayload', body, 'application/json')

        // Process...
        def result = transform(body)

        log?.setStringProperty('ProcessingStatus', 'SUCCESS')
        log?.setStringProperty('RecordCount', result.size().toString())

        message.setBody(result)
    } catch (Exception e) {
        // Set error details for exception subprocess
        message.setProperty('ErrorMessage', e.message)
        message.setProperty('ErrorClass', e.class.simpleName)
        message.setProperty('ErrorTimestamp', new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'"))

        log?.setStringProperty('ProcessingStatus', 'ERROR')
        log?.setStringProperty('ErrorDetail', e.message)

        // Re-throw to trigger error handling
        throw e
    }

    return message
}
```

### Pattern 3: Groovy Script — Dynamic Routing

```groovy
import com.sap.gateway.ip.core.customdev.util.Message

def Message processData(Message message) {
    def body = new groovy.json.JsonSlurper().parseText(message.getBody(String))

    // Determine route based on payload
    def routeTarget = switch(body.documentType) {
        case 'INVOICE'     -> 'InvoiceEndpoint'
        case 'CREDIT_MEMO' -> 'CreditMemoEndpoint'
        case 'PO'          -> 'PurchaseOrderEndpoint'
        default            -> 'DefaultEndpoint'
    }

    // Set routing header for Router step
    message.setHeader('RouteTarget', routeTarget)

    // Set dynamic endpoint URL
    def endpoints = [
        'InvoiceEndpoint':     'https://erp.example.com/api/invoices',
        'CreditMemoEndpoint':  'https://erp.example.com/api/credit-memos',
        'PurchaseOrderEndpoint': 'https://erp.example.com/api/purchase-orders',
        'DefaultEndpoint':     'https://erp.example.com/api/documents'
    ]
    message.setProperty('DynamicEndpointURL', endpoints[routeTarget])

    return message
}
```

### Pattern 4: API Management — Rate Limiting Policy

```xml
<!-- Spike Arrest Policy -->
<SpikeArrest async="false" continueOnError="false" enabled="true"
  xmlns="http://www.sap.com/apimgmt">
  <DisplayName>Spike Arrest - 30ps</DisplayName>
  <Rate>30ps</Rate>  <!-- 30 per second -->
  <Identifier ref="request.header.X-Client-ID"/>
</SpikeArrest>

<!-- Quota Policy (per API key) -->
<Quota async="false" continueOnError="false" enabled="true" type="calendar"
  xmlns="http://www.sap.com/apimgmt">
  <DisplayName>Monthly Quota</DisplayName>
  <Allow count="10000"/>
  <Interval>1</Interval>
  <TimeUnit>month</TimeUnit>
  <StartTime>2026-01-01 00:00:00</StartTime>
  <Identifier ref="request.header.apiKey"/>
  <Distributed>true</Distributed>
</Quota>

<!-- OAuth v2.0 Validation -->
<OAuthV2 async="false" continueOnError="false" enabled="true"
  xmlns="http://www.sap.com/apimgmt">
  <DisplayName>Verify OAuth Token</DisplayName>
  <Operation>VerifyAccessToken</Operation>
  <AccessToken>request.header.Authorization</AccessToken>
  <Scope>read write</Scope>
</OAuthV2>

<!-- Response Caching -->
<ResponseCache async="false" continueOnError="false" enabled="true"
  xmlns="http://www.sap.com/apimgmt">
  <DisplayName>Cache GET responses</DisplayName>
  <CacheKey>
    <KeyFragment ref="request.uri"/>
    <KeyFragment ref="request.header.Accept"/>
  </CacheKey>
  <ExpirySettings>
    <TimeoutInSec>300</TimeoutInSec>
  </ExpirySettings>
  <SkipCacheLookup>request.verb != "GET"</SkipCacheLookup>
</ResponseCache>
```

### Pattern 5: XSLT Mapping — IDoc to JSON

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:idoc="urn:sap-com:document:sap:idoc:messages">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:template match="/">
    <xsl:text>{"orders":[</xsl:text>
    <xsl:for-each select="//ORDERS05/IDOC">
      <xsl:if test="position() > 1">,</xsl:if>
      <xsl:text>{"orderNumber":"</xsl:text>
      <xsl:value-of select="E1EDK01/BELNR"/>
      <xsl:text>","orderDate":"</xsl:text>
      <xsl:value-of select="concat(
        substring(E1EDK01/DATUM,1,4),'-',
        substring(E1EDK01/DATUM,5,2),'-',
        substring(E1EDK01/DATUM,7,2))"/>
      <xsl:text>","items":[</xsl:text>
      <xsl:for-each select="E1EDP01">
        <xsl:if test="position() > 1">,</xsl:if>
        <xsl:text>{"lineItem":"</xsl:text>
        <xsl:value-of select="POSEX"/>
        <xsl:text>","material":"</xsl:text>
        <xsl:value-of select="normalize-space(MATNR)"/>
        <xsl:text>","quantity":</xsl:text>
        <xsl:value-of select="MENGE"/>
        <xsl:text>}</xsl:text>
      </xsl:for-each>
      <xsl:text>]}</xsl:text>
    </xsl:for-each>
    <xsl:text>]}</xsl:text>
  </xsl:template>
</xsl:stylesheet>
```

### Pattern 6: B2B Integration — AS2 with TPM

```
Trading Partner Setup:
┌──────────────┐    AS2/HTTPS    ┌──────────────────┐
│   Partner A   │───────────────►│  Integration Suite │
│  (Supplier)   │  EDIFACT msg   │  ┌──────────────┐ │
│               │◄───────────────│  │  TPM Config   │ │
└──────────────┘    AS2 MDN      │  │  - Partner ID │ │
                                 │  │  - AS2 ID     │ │
                                 │  │  - Certificate│ │
                                 │  │  - Agreement  │ │
                                 │  └──────┬───────┘ │
                                 │         ▼         │
                                 │  ┌──────────────┐ │
                                 │  │  iFlow        │ │
                                 │  │  (EDI→XML→    │ │
                                 │  │   IDoc/OData) │ │
                                 │  └──────┬───────┘ │
                                 └─────────┼─────────┘
                                           ▼
                                    SAP S/4HANA
```

**TPM Configuration checklist:**
1. Create Trading Partner profile (AS2 ID, certificates)
2. Define Agreement (message type: ORDERS, INVOIC, DESADV)
3. Configure B2B adapter in iFlow (AS2 sender/receiver)
4. Map EDI segments to SAP IDoc/API structure
5. Set up MDN (Message Disposition Notification) for acknowledgment
6. Test with partner's test environment before go-live

## Error Catalog

| Error | Context | Root Cause | Fix |
|-------|---------|------------|-----|
| Groovy: `NullPointerException` | Script step | Accessing null property | Add null-safe operator `?.` and default values |
| Groovy: `ClassNotFoundException` | Custom library | JAR not uploaded to tenant | Upload via Integration Content → Resources |
| `HTTP 429` | API Management | Rate limit/quota exceeded | Adjust policy; contact API provider |
| `MPL: FAILED` | Message Processing Log | iFlow step error | Check MPL attachments and trace for root cause |
| `Certificate expired` | Receiver adapter | SSL/TLS cert expiration | Rotate certificate in Security Material |
| AS2: `MDN negative` | B2B | Partner rejected message | Check EDI validation; verify message structure |
| `Mapping error` | Message Mapping | Source/target mismatch | Compare source XML structure with mapping definition |
| Edge: `Pod CrashLoopBackOff` | Edge Integration Cell | Memory/config issue | Check pod logs; increase resource limits |
| `Credential not found` | Adapter auth | Missing Security Material | Deploy OAuth/Basic auth credentials to tenant |
| `Queue full` | JMS adapter | Consumer too slow | Scale consumer iFlow; increase queue depth |

## Performance Tips

1. **Groovy: Reuse parsers** — Compile JsonSlurper once, reuse across messages; avoid `new` in hot paths
2. **Streaming for large payloads** — Use Groovy `XMLStreamReader` instead of DOM for >10 MB XML
3. **Content Modifier over Script** — Use Content Modifier for simple header/property changes; Groovy adds overhead
4. **JMS queues for decoupling** — Use JMS between sender and receiver iFlows for retry and buffering
5. **API caching** — Enable ResponseCache policy for read-heavy APIs; 5-min cache reduces backend calls 80%+
6. **Parallel processing** — Use Splitter (parallel) + Aggregator for batch processing
7. **Edge Cell for latency** — Deploy latency-sensitive iFlows to Edge; keep cloud for management only
8. **Minimize trace logging** — Trace-level logging in production impacts throughput; use only for debugging

## Gotchas

- **Groovy sandbox**: Integration Suite Groovy runs in a restricted sandbox — no file I/O, no network calls (use adapters)
- **Groovy version**: Integration Suite uses Groovy 2.4.x (not 4.x); avoid newer syntax
- **iFlow versioning**: Each deploy creates a new version; rollback by redeploying older version
- **Edge Cell updates**: Edge runtime must be kept within 2 versions of cloud; auto-update recommended
- **API proxy vs. iFlow**: API Management proxies are for facade/security; iFlows for transformation/routing
- **JMS queue limits**: Default 30 queues per tenant; each 9.3 GB max; request increase via support ticket
- **B2B certificates**: Partner certificates expire; set calendar reminders for rotation
