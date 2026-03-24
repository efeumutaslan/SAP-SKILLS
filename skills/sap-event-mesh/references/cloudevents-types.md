# SAP Event Mesh — CloudEvents Types Reference

## S/4HANA Business Events

### Sales
| Event Type | Trigger | Key Data |
|-----------|---------|----------|
| `sap.s4.beh.salesorder.v1.SalesOrder.Created.v1` | SO created | SalesOrder, SalesOrderType |
| `sap.s4.beh.salesorder.v1.SalesOrder.Changed.v1` | SO updated | SalesOrder, ChangedFields |
| `sap.s4.beh.billingdocument.v1.BillingDocument.Created.v1` | Invoice posted | BillingDocument, BillingDocumentType |
| `sap.s4.beh.deliverydocument.v1.DeliveryDocument.Created.v1` | Delivery created | DeliveryDocument |

### Procurement
| Event Type | Trigger | Key Data |
|-----------|---------|----------|
| `sap.s4.beh.purchaseorder.v1.PurchaseOrder.Created.v1` | PO created | PurchaseOrder, Supplier |
| `sap.s4.beh.purchaserequisition.v1.PurchaseRequisition.Created.v1` | PR created | PurchaseRequisition |
| `sap.s4.beh.supplier.v1.Supplier.Created.v1` | Vendor master created | Supplier |

### Finance
| Event Type | Trigger | Key Data |
|-----------|---------|----------|
| `sap.s4.beh.journalentry.v1.JournalEntry.Created.v1` | FI posting | CompanyCode, FiscalYear, AccountingDocument |
| `sap.s4.beh.costcenter.v1.CostCenter.Changed.v1` | CC changed | CostCenter, ControllingArea |

### Master Data
| Event Type | Trigger | Key Data |
|-----------|---------|----------|
| `sap.s4.beh.businesspartner.v1.BusinessPartner.Created.v1` | BP created | BusinessPartner |
| `sap.s4.beh.businesspartner.v1.BusinessPartner.Changed.v1` | BP changed | BusinessPartner, ChangedFields |
| `sap.s4.beh.product.v1.Product.Created.v1` | Material created | Product |

## CloudEvents Envelope

```json
{
  "specversion": "1.0",
  "type": "sap.s4.beh.salesorder.v1.SalesOrder.Created.v1",
  "source": "/default/sap.s4.beh/S4H",
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "time": "2025-03-15T10:30:00Z",
  "datacontenttype": "application/json",
  "data": {
    "SalesOrder": "0000000100",
    "SalesOrderType": "OR"
  }
}
```

## Queue Naming Convention

```
<namespace>/<object>/<version>
sap/S4HANAOD/S4H/ce/sap/s4/beh/salesorder/v1/SalesOrder/Created/v1
```

## Topic Rules (Subscription Filters)

```
# Exact match
sap/s4/beh/salesorder/v1/SalesOrder/Created/v1

# Wildcard: all sales order events
sap/s4/beh/salesorder/v1/SalesOrder/+/v1

# Multi-level wildcard: all S/4 events
sap/s4/beh/#
```

## CAP Integration

```javascript
// package.json
{ "cds": { "requires": {
  "messaging": {
    "kind": "enterprise-messaging",
    "queue": { "name": "myapp/orders" },
    "webhook": { "waitForAck": true }
  }
}}}

// srv/order-events.js
module.exports = (srv) => {
  const S4beh = 'sap.s4.beh.salesorder.v1.SalesOrder';
  srv.on(`${S4beh}.Created.v1`, async (msg) => {
    const { SalesOrder } = msg.data;
    console.log(`New SO: ${SalesOrder}`);
  });
};
```
