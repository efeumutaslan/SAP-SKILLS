# SAP Integration Suite — Groovy Script Patterns

## Message Processing Basics

```groovy
import com.sap.gateway.ip.core.customdev.util.Message

def Message processData(Message message) {
    def body = message.getBody(String)
    def headers = message.getHeaders()
    def properties = message.getProperties()

    // Modify body
    message.setBody(body.replace("old", "new"))

    // Set header
    message.setHeader("X-Custom", "value")

    // Set property (exchange-scoped)
    message.setProperty("ProcessedAt", new Date().toString())

    return message
}
```

## JSON Transformation

```groovy
import groovy.json.JsonSlurper
import groovy.json.JsonOutput

def Message processData(Message message) {
    def body = message.getBody(String)
    def json = new JsonSlurper().parseText(body)

    // Transform structure
    def output = json.d.results.collect { item ->
        [
            id:          item.MaterialNumber,
            description: item.MaterialDescription,
            type:        item.MaterialType,
            uom:         item.BaseUnit,
            price:       item.StandardPrice as BigDecimal
        ]
    }

    message.setBody(JsonOutput.prettyPrint(JsonOutput.toJson(output)))
    message.setHeader("Content-Type", "application/json")
    return message
}
```

## XML Processing

```groovy
def Message processData(Message message) {
    def body = message.getBody(String)
    def xml = new XmlSlurper().parseText(body)

    // Read values
    def orderId = xml.OrderID.text()
    def items = xml.Items.Item

    // Build new XML
    def writer = new StringWriter()
    def builder = new groovy.xml.MarkupBuilder(writer)
    builder.Order {
        OrderNumber(orderId)
        items.each { item ->
            LineItem {
                Material(item.MaterialNumber.text())
                Quantity(item.Quantity.text())
                Amount(item.NetAmount.text())
            }
        }
    }

    message.setBody(writer.toString())
    return message
}
```

## Error Handling & Logging

```groovy
import org.slf4j.LoggerFactory

def Message processData(Message message) {
    def log = LoggerFactory.getLogger("script.ErrorHandler")

    try {
        def body = message.getBody(String)
        if (!body || body.trim().isEmpty()) {
            throw new Exception("Empty payload received")
        }

        // Process...
        log.info("Successfully processed message: ${message.getHeaders().get('SAP_MessageProcessingLogID')}")

    } catch (Exception e) {
        log.error("Processing failed: ${e.message}", e)
        message.setProperty("ErrorMessage", e.message)
        message.setProperty("ErrorTimestamp", new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'"))
        message.setHeader("CamelHttpResponseCode", 500)
        throw e  // Re-throw to trigger error handling route
    }
    return message
}
```

## Dynamic Routing

```groovy
def Message processData(Message message) {
    def body = new groovy.json.JsonSlurper().parseText(message.getBody(String))
    def docType = body.DocumentType

    // Set endpoint dynamically
    def endpointMap = [
        "PO": "/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV",
        "SO": "/sap/opu/odata/sap/API_SALES_ORDER_SRV",
        "BP": "/sap/opu/odata/sap/API_BUSINESS_PARTNER"
    ]

    def endpoint = endpointMap[docType]
    if (!endpoint) {
        throw new Exception("Unknown document type: ${docType}")
    }

    message.setProperty("DynamicEndpoint", endpoint)
    message.setHeader("CamelHttpPath", endpoint)
    return message
}
```

## Pagination (OData $skip/$top)

```groovy
def Message processData(Message message) {
    def skip = message.getProperty("PageOffset") as Integer ?: 0
    def top = 1000
    def totalCount = message.getProperty("TotalCount") as Integer ?: 0

    // Build URL with pagination
    def baseUrl = message.getProperty("BaseUrl")
    def url = "${baseUrl}?\$top=${top}&\$skip=${skip}&\$inlinecount=allpages"

    message.setProperty("PageOffset", skip + top)
    message.setProperty("HasMorePages", (skip + top) < totalCount)
    message.setHeader("CamelHttpUri", url)

    return message
}
```

## CSRF Token Handling

```groovy
// Pre-request: Fetch CSRF token
def Message fetchCsrfToken(Message message) {
    message.setHeader("X-CSRF-Token", "Fetch")
    message.setHeader("CamelHttpMethod", "GET")
    return message
}

// Post-fetch: Extract and set token
def Message setCsrfToken(Message message) {
    def token = message.getHeaders().get("X-CSRF-Token")
    message.setProperty("CsrfToken", token)
    return message
}

// Use in POST/PUT/DELETE
def Message applyToken(Message message) {
    def token = message.getProperty("CsrfToken")
    message.setHeader("X-CSRF-Token", token)
    return message
}
```

## Credential Store Access

```groovy
import com.sap.it.api.securestore.SecureStoreService
import com.sap.it.api.ITApiFactory

def Message processData(Message message) {
    def secureStore = ITApiFactory.getService(SecureStoreService, null)
    def credential = secureStore.getUserCredential("MyCredentialAlias")

    def username = credential.getUsername()
    def password = new String(credential.getPassword())

    message.setProperty("ApiUser", username)
    message.setProperty("ApiPassword", password)
    return message
}
```
