declare module "@salesforce/apex/IntegrationSyncController.getSyncConfigurations" {
  export default function getSyncConfigurations(param: {connectionId: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.getPicklistValues" {
  export default function getPicklistValues(param: {objectName: any, fieldName: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.saveFieldMappings" {
  export default function saveFieldMappings(param: {mappingData: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.deleteSyncConfiguration" {
  export default function deleteSyncConfiguration(param: {syncId: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.getExistingMappings" {
  export default function getExistingMappings(param: {syncId: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.updateSyncStatus" {
  export default function updateSyncStatus(param: {syncId: any, status: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.createSyncConfiguration" {
  export default function createSyncConfiguration(param: {syncData: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.getSalesforceFields" {
  export default function getSalesforceFields(param: {objectName: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.getSyncConfigurationById" {
  export default function getSyncConfigurationById(param: {syncId: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.updateSyncConfiguration" {
  export default function updateSyncConfiguration(param: {syncId: any, syncData: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationSyncController.runHistoricalSync" {
  export default function runHistoricalSync(param: {syncId: any}): Promise<any>;
}
