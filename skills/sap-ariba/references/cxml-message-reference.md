# SAP Ariba cXML Message Reference

## Common cXML Document Types

| Document | Direction | Purpose |
|----------|-----------|---------|
| `PunchOutSetupRequest` | Buyer → Supplier | Initiate PunchOut session |
| `PunchOutSetupResponse` | Supplier → Buyer | Return PunchOut URL |
| `PunchOutOrderMessage` | Supplier → Buyer | Cart contents from PunchOut |
| `OrderRequest` | Buyer → Supplier | Purchase Order |
| `ConfirmationRequest` | Supplier → Buyer | Order confirmation |
| `ShipNoticeRequest` | Supplier → Buyer | ASN (Advance Shipping Notice) |
| `InvoiceDetailRequest` | Supplier → Buyer | Invoice |
| `StatusUpdateRequest` | Either | Status update on order/line |

## PunchOut Flow

```
Buyer App                    Ariba Network              Supplier Site
    │                             │                          │
    ├─PunchOutSetupRequest──────►│──PunchOutSetupRequest───►│
    │                             │                          │
    │◄─PunchOutSetupResponse─────│◄─PunchOutSetupResponse──│
    │                             │                          │
    │─────── User browses supplier catalog ────────────────►│
    │                             │                          │
    │◄─PunchOutOrderMessage──────│◄─PunchOutOrderMessage───│
    │  (cart items in cXML)       │                          │
```

## cXML Envelope Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML SYSTEM "http://xml.cxml.org/schemas/cXML/1.2.053/cXML.dtd">
<cXML payloadID="{{PAYLOAD_ID}}" timestamp="{{ISO_TIMESTAMP}}">
  <Header>
    <From>
      <Credential domain="NetworkId">
        <Identity>{{SENDER_ANID}}</Identity>
      </Credential>
    </From>
    <To>
      <Credential domain="NetworkId">
        <Identity>{{RECEIVER_ANID}}</Identity>
      </Credential>
    </To>
    <Sender>
      <Credential domain="NetworkId">
        <Identity>{{SENDER_ANID}}</Identity>
        <SharedSecret>{{SHARED_SECRET}}</SharedSecret>
      </Credential>
      <UserAgent>{{APP_NAME}}</UserAgent>
    </Sender>
  </Header>
  <Request>
    <!-- Document-specific content -->
  </Request>
</cXML>
```

## OrderRequest Example

```xml
<Request>
  <OrderRequest>
    <OrderRequestHeader orderID="PO-001" orderDate="2025-03-15"
      type="new">
      <Total>
        <Money currency="USD">1500.00</Money>
      </Total>
      <ShipTo>
        <Address>
          <PostalAddress>
            <Street>123 Main St</Street>
            <City>Walldorf</City>
            <PostalCode>69190</PostalCode>
            <Country isoCountryCode="DE">Germany</Country>
          </PostalAddress>
        </Address>
      </ShipTo>
      <BillTo>
        <Address addressID="BILL-001"/>
      </BillTo>
    </OrderRequestHeader>
    <ItemOut quantity="10" lineNumber="1">
      <ItemID>
        <SupplierPartID>MAT-12345</SupplierPartID>
      </ItemID>
      <ItemDetail>
        <UnitPrice><Money currency="USD">150.00</Money></UnitPrice>
        <Description xml:lang="en">Widget A</Description>
        <UnitOfMeasure>EA</UnitOfMeasure>
      </ItemDetail>
    </ItemOut>
  </OrderRequest>
</Request>
```

## Ariba APIs (REST)

| API | Endpoint Pattern | Auth |
|-----|-----------------|------|
| Procurement | `/api/procurement/v2/` | OAuth2 |
| Sourcing | `/api/sourcing/v2/` | OAuth2 |
| Contracts | `/api/contracts/v1/` | OAuth2 |
| Supplier Management | `/api/supplier-management/v2/` | OAuth2 |
| Analytics (Operational) | `/api/analytics-reporting-view/v1/` | OAuth2 |

## CIG (Cloud Integration Gateway) Events

| Event | Description |
|-------|-------------|
| `PurchaseOrderRequest` | PO from S/4 → Ariba |
| `PurchaseOrderConfirmation` | Confirmation Ariba → S/4 |
| `InvoiceRequest` | Invoice from supplier |
| `GoodsReceipt` | GR from S/4 for 3-way match |
