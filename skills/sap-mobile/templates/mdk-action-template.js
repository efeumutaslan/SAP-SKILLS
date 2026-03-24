// SAP Mobile Development Kit (MDK) — Custom Action Template
// Replace: {{ENTITY_SET}}, {{SERVICE_PATH}}, {{FIELDS}}
// File: Rules/{{ActionName}}.js

/**
 * Custom action rule for MDK application
 * @param {IClientAPI} clientAPI - MDK Client API
 */
export default function {{ActionName}}(clientAPI) {
  // ============================================================
  // Pattern 1: Create Entity with Validation
  // ============================================================
  const createWithValidation = async (clientAPI) => {
    const pageProxy = clientAPI.getPageProxy();

    // Read form controls
    const entityData = {
      {{FIELD1}}: pageProxy.evaluateTargetPath('#Control:{{FIELD1}}/#Value'),
      {{FIELD2}}: pageProxy.evaluateTargetPath('#Control:{{FIELD2}}/#Value'),
      {{FIELD3}}: Number(pageProxy.evaluateTargetPath('#Control:{{FIELD3}}/#Value')),
    };

    // Validate
    if (!entityData.{{FIELD1}}) {
      return clientAPI.executeAction('/SAP_SKILLS/Actions/ValidationError.action', {
        Message: '{{FIELD1}} is required',
      });
    }

    // Create via OData
    return clientAPI.executeAction('/SAP_SKILLS/Actions/CreateEntity.action', {
      Properties: entityData,
    });
  };

  // ============================================================
  // Pattern 2: Offline Sync with Error Handling
  // ============================================================
  const syncWithErrorHandling = async (clientAPI) => {
    try {
      // Show busy indicator
      clientAPI.showActivityIndicator('Synchronizing...');

      // Upload pending changes
      await clientAPI.executeAction('/SAP_SKILLS/Actions/UploadOffline.action');

      // Download latest data
      await clientAPI.executeAction('/SAP_SKILLS/Actions/DownloadOffline.action');

      clientAPI.dismissActivityIndicator();
      return clientAPI.executeAction('/SAP_SKILLS/Actions/SyncSuccess.action');
    } catch (error) {
      clientAPI.dismissActivityIndicator();
      const errorMessage = error.message || 'Sync failed. Check connectivity.';
      return clientAPI.executeAction('/SAP_SKILLS/Actions/SyncError.action', {
        Message: errorMessage,
      });
    }
  };

  // ============================================================
  // Pattern 3: Dynamic Navigation
  // ============================================================
  const navigateByStatus = (clientAPI) => {
    const binding = clientAPI.getPageProxy().binding;
    const status = binding.Status;

    const routeMap = {
      NEW: '/SAP_SKILLS/Actions/NavToEdit.action',
      APPROVED: '/SAP_SKILLS/Actions/NavToDetail.action',
      REJECTED: '/SAP_SKILLS/Actions/NavToReject.action',
    };

    const action = routeMap[status] || '/SAP_SKILLS/Actions/NavToDetail.action';
    return clientAPI.executeAction(action);
  };

  // ============================================================
  // Pattern 4: Barcode/QR Scan
  // ============================================================
  const scanAndLookup = async (clientAPI) => {
    try {
      const result = await clientAPI.nativescript.BarcodeScanner.scan({
        formats: 'QR_CODE,EAN_13,CODE_128',
        message: 'Scan material barcode',
        showFlipCameraButton: true,
      });

      if (result && result.text) {
        // Query OData with scanned value
        const service = '/SAP_SKILLS/Services/{{SERVICE_PATH}}.service';
        const queryOptions = `$filter=MaterialNumber eq '${result.text}'`;
        const materials = await clientAPI.read(
          service,
          '{{ENTITY_SET}}',
          [],
          queryOptions
        );

        if (materials.length > 0) {
          clientAPI.getPageProxy().setActionBinding(materials[0]);
          return clientAPI.executeAction('/SAP_SKILLS/Actions/NavToMaterial.action');
        } else {
          return clientAPI.executeAction('/SAP_SKILLS/Actions/NotFound.action');
        }
      }
    } catch (error) {
      console.log('Scan cancelled or failed:', error);
    }
  };

  // ============================================================
  // Pattern 5: Geo-Location Capture
  // ============================================================
  const captureLocation = async (clientAPI) => {
    const location = await clientAPI.nativescript.geolocation.getCurrentLocation({
      desiredAccuracy: 3, // HIGH
      timeout: 10000,
    });

    return {
      Latitude: location.latitude.toString(),
      Longitude: location.longitude.toString(),
      Accuracy: location.horizontalAccuracy.toString(),
      Timestamp: new Date().toISOString(),
    };
  };
}
