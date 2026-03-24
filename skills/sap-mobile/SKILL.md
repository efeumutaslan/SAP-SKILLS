---
name: sap-mobile
description: |
  SAP Mobile development skill. Use when: building mobile apps with SAP Mobile Development Kit
  (MDK), SAP BTP SDK for iOS/Android, SAP Mobile Cards, SAP Mobile Start, configuring SAP
  Mobile Services, implementing offline-capable mobile apps, using OData offline store, push
  notifications, mobile security (app passcode, biometrics, certificate pinning), or deploying
  enterprise mobile apps. Covers MDK, native SDK, and mobile operations.
license: MIT
metadata:
  author: SAP Skills Community
  version: "1.0.0"
  last_verified: "2026-03-24"
---

# SAP Mobile Development

## Related Skills
- `sap-s4hana-extensibility` — Backend OData services consumed by mobile apps
- `sap-security-authorization` — Mobile app authentication and security policies
- `sap-build-apps` — Alternative low-code approach for mobile apps

## Quick Start

**Choose your mobile framework:**

| Framework | Language | Offline | Best For |
|-----------|----------|---------|----------|
| **MDK (Mobile Dev Kit)** | Metadata/JS | Built-in | Cross-platform business apps |
| **BTP SDK for iOS** | Swift | Built-in | Native iOS enterprise apps |
| **BTP SDK for Android** | Kotlin/Java | Built-in | Native Android enterprise apps |
| **SAP Build Apps** | No-code | Manual | Simple apps, citizen developers |
| **SAP Mobile Start** | Config only | N/A | Unified mobile launchpad |

**MDK Quick Start:**
1. SAP Business Application Studio → MDK project from template
2. Define application → Pages → Actions → Rules → Services
3. Deploy to Mobile Services → Test with SAP Mobile Services Client

## Core Concepts

### SAP Mobile Services
Central management platform for all SAP mobile apps:
- **App Configuration** — Define app features, security, connectivity
- **Push Notifications** — APNS (iOS), FCM (Android) integration
- **Offline Store** — OData offline delta sync engine
- **App Update** — OTA (over-the-air) updates without app store
- **Usage Analytics** — User sessions, feature usage, crash reports
- **Security Policies** — Passcode, biometrics, jailbreak detection

### Offline Architecture
```
Mobile App ──► Local SQLite DB ──► Offline OData Store
                                        │
                                   [Sync Engine]
                                        │
                              SAP Mobile Services
                                        │
                              Backend OData Service
```

**Sync modes:**
| Mode | Description | Use Case |
|------|-------------|----------|
| **Download** | Server → device | Initial load, refresh |
| **Upload** | Device → server | Submit local changes |
| **Delta sync** | Changed records only | Incremental updates |
| **Defining requests** | Subset of data per entity | Control offline data scope |

### MDK Application Structure
```
MDKApp/
├── Application.app           # App-level config
├── Pages/
│   ├── Main.page             # Landing page
│   ├── CustomerList.page     # List page
│   └── CustomerDetail.page   # Detail page
├── Actions/
│   ├── Service/
│   │   ├── InitializeOffline.action
│   │   ├── SyncStartedMessage.action
│   │   └── UploadOffline.action
│   └── Customers/
│       ├── CreateCustomer.action
│       └── UpdateCustomer.action
├── Rules/
│   ├── OnWillUpdate.js
│   └── FormatAddress.js
├── Services/
│   └── MyODataService.service
├── Styles/
│   └── Styles.less
└── i18n/
    └── i18n.properties
```

## Common Patterns

### Pattern 1: MDK List Page with Search

```json
// Pages/CustomerList.page
{
  "_Type": "Page",
  "_Name": "CustomerList",
  "Caption": "Customers",
  "Controls": [
    {
      "_Type": "Control.Type.SectionedTable",
      "_Name": "CustomerTable",
      "Sections": [
        {
          "_Type": "Section.Type.ObjectTable",
          "Target": {
            "EntitySet": "Customers",
            "Service": "/MDKApp/Services/MyODataService.service",
            "QueryOptions": "$orderby=CompanyName&$top=50"
          },
          "ObjectCell": {
            "Title": "{CompanyName}",
            "Subhead": "{CustomerID}",
            "Description": "{City}, {Country}",
            "StatusText": "{ContactName}",
            "AccessoryType": "DisclosureIndicator",
            "OnPress": "/MDKApp/Actions/Customers/NavToDetail.action"
          },
          "Search": {
            "Enabled": true,
            "Placeholder": "Search customers...",
            "BarcodeScanner": true
          },
          "EmptySection": {
            "Caption": "No customers found"
          }
        }
      ]
    }
  ],
  "ToolBar": {
    "Items": [
      {
        "_Type": "Control.Type.ToolbarItem",
        "_Name": "AddButton",
        "Caption": "Add",
        "SystemItem": "Add",
        "OnPress": "/MDKApp/Actions/Customers/NavToCreate.action"
      }
    ]
  }
}
```

### Pattern 2: Offline Initialization Action

```json
// Actions/Service/InitializeOffline.action
{
  "_Type": "Action.Type.ODataService.Initialize",
  "_Name": "InitializeOffline",
  "Service": "/MDKApp/Services/MyODataService.service",
  "ShowActivityIndicator": true,
  "OnSuccess": "/MDKApp/Actions/Service/InitializeOfflineSuccessMessage.action",
  "OnFailure": "/MDKApp/Actions/Service/InitializeOfflineFailureMessage.action",
  "DefiningRequests": [
    {
      "Name": "CustomersReq",
      "Query": "/Customers",
      "AutomaticallyRetrievesStreams": false
    },
    {
      "Name": "OrdersReq",
      "Query": "/Orders?$filter=OrderDate gt datetime'2026-01-01T00:00:00'",
      "AutomaticallyRetrievesStreams": false
    }
  ]
}
```

### Pattern 3: MDK Rule — Custom Validation

```javascript
// Rules/ValidateCustomer.js
/**
 * @param {IClientAPI} clientAPI
 * @returns {string} Empty string if valid, error message if invalid
 */
export default function ValidateCustomer(clientAPI) {
    const formProxy = clientAPI.getPageProxy().getControl('FormCellContainer');
    const companyName = formProxy.getControl('CompanyName').getValue();
    const email = formProxy.getControl('Email').getValue();
    const phone = formProxy.getControl('Phone').getValue();

    if (!companyName || companyName.trim().length < 2) {
        return 'Company name must be at least 2 characters';
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (email && !emailRegex.test(email)) {
        return 'Invalid email address';
    }

    if (phone && !/^\+?[\d\s-()]{7,15}$/.test(phone)) {
        return 'Invalid phone number';
    }

    return '';
}
```

### Pattern 4: Push Notification (iOS SDK — Swift)

```swift
import SAPFoundation
import SAPFiori
import UserNotifications

class PushNotificationManager {
    static func registerForPush(application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    static func sendTokenToMobileServices(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // Register with SAP Mobile Services
        let url = URL(string: "\(mobileServicesURL)/mobileservices/push/v1/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "deviceToken": tokenString,
            "deviceType": "iOS",
            "applicationId": Bundle.main.bundleIdentifier ?? ""
        ])

        URLSession.shared.dataTask(with: request).resume()
    }
}
```

### Pattern 5: Offline Sync with Conflict Resolution (Android SDK)

```kotlin
import com.sap.cloud.mobile.odata.offline.*

class OfflineSyncManager(private val offlineStore: OfflineODataProvider) {

    fun syncData(callback: SyncCallback) {
        // Upload local changes first
        offlineStore.upload(
            successHandler = {
                // Then download server changes
                offlineStore.download(
                    successHandler = {
                        callback.onSuccess()
                    },
                    failureHandler = { error ->
                        callback.onError("Download failed: ${error.message}")
                    }
                )
            },
            failureHandler = { error ->
                if (error is OfflineODataException &&
                    error.errorCode == OfflineODataErrorCode.UPLOAD_CONFLICT) {
                    handleConflict(error, callback)
                } else {
                    callback.onError("Upload failed: ${error.message}")
                }
            }
        )
    }

    private fun handleConflict(error: OfflineODataException, callback: SyncCallback) {
        val errorArchive = offlineStore.getErrorArchive()
        for (entry in errorArchive) {
            // Strategy: server wins (discard local change)
            entry.cancelUpload()
            // Alternative: client wins — entry.retryUpload()
        }
        // Retry sync after conflict resolution
        syncData(callback)
    }

    interface SyncCallback {
        fun onSuccess()
        fun onError(message: String)
    }
}
```

### Pattern 6: Mobile Security Configuration

```json
// Mobile Services — App Security Config
{
  "security": {
    "passcode": {
      "enabled": true,
      "minLength": 6,
      "hasDigit": true,
      "retryLimit": 5,
      "lockTimeout": 300,
      "biometricEnabled": true
    },
    "certificatePinning": {
      "enabled": true,
      "pins": [
        {
          "host": "*.hana.ondemand.com",
          "pins": ["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="]
        }
      ]
    },
    "rootDetection": {
      "enabled": true,
      "action": "WARN"
    },
    "dataProtection": {
      "encryptDatabase": true,
      "preventScreenCapture": true,
      "clipboardTimeout": 60
    }
  }
}
```

## Error Catalog

| Error | Message | Root Cause | Fix |
|-------|---------|------------|-----|
| `Offline init failed` | Cannot create offline store | Defining request error or backend down | Check OData service; validate defining request query |
| `Upload conflict` | Entity modified on server | Concurrent edit during offline period | Implement conflict resolution (server/client wins) |
| `Push: Token invalid` | APNS/FCM token rejected | App reinstalled or token expired | Re-register device token on app launch |
| `Sync timeout` | Download timed out | Large dataset or slow network | Reduce defining request scope; increase timeout |
| `Certificate error` | SSL handshake failed | Certificate pinning mismatch | Update pinned certificates; check cert rotation |
| `Passcode locked` | Too many failed attempts | User exceeded retry limit | Admin reset via Mobile Services console |
| `MDK deploy error` | Metadata upload failed | Invalid page/action JSON | Validate JSON syntax; check MDK version compatibility |
| `OData 413` | Payload too large | Offline store sync payload exceeds limit | Split defining requests; limit data scope |

## Performance Tips

1. **Defining requests** — Scope offline data narrowly; don't sync entire entity sets
2. **Delta tokens** — Enable server-side delta tokens for incremental sync
3. **Image handling** — Download images on demand, not during sync; use thumbnail URLs
4. **Batch size** — Configure upload batch size (default 100); reduce for slow networks
5. **Sync frequency** — Don't auto-sync on every app resume; use manual or timed sync (every 15-30 min)
6. **MDK page loading** — Use lazy loading for detail pages; preload only list pages
7. **SQLite optimization** — Offline store uses SQLite; keep total offline data under 500 MB

## Gotchas

- **MDK vs. native SDK**: MDK is cross-platform but less flexible; native SDKs offer full platform APIs
- **Offline data scope**: Defining requests determine what's available offline — missing data = blank screens
- **iOS enterprise distribution**: Apps need MDM or Apple Business Manager for enterprise deployment
- **Mobile Services regions**: Ensure Mobile Services instance is in same BTP region as backend
- **OData version**: Offline OData store supports V2 and V4; check backend service version
- **App update strategy**: MDK supports OTA updates for metadata; native apps need app store updates
