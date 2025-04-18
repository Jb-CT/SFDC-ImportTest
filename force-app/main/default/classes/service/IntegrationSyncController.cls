/**
 * @class IntegrationSyncController
 * @description Controller class for handling CleverTap integration sync configurations and field mappings.
 * Acts as a facade for more specialized manager and utility classes.
 */
public with sharing class IntegrationSyncController {
    private static SyncConfigurationManager syncConfigManager {
        get {
            if(syncConfigManager == null) {
                syncConfigManager = new SyncConfigurationManager();
            }
            return syncConfigManager;
        }
        set;
    }
    
    private static FieldMappingManager fieldMappingManager {
        get {
            if(fieldMappingManager == null) {
                fieldMappingManager = new FieldMappingManager();
            }
            return fieldMappingManager;
        }
        set;
    }
    
    private static SchemaUtility schemaUtility {
        get {
            if(schemaUtility == null) {
                schemaUtility = new SchemaUtility();
            }
            return schemaUtility;
        }
        set;
    }

    @AuraEnabled(cacheable=true)
    public static List<SyncConfigurationManager.SyncConfigWrapper> getSyncConfigurations(String connectionId) {
        return syncConfigManager.getSyncConfigurations(connectionId);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        return schemaUtility.getPicklistValues(objectName, fieldName);
    }

    @AuraEnabled
    public static void saveFieldMappings(String mappingData) {
        fieldMappingManager.saveFieldMappings(mappingData);
    }

    @AuraEnabled
    public static void deleteSyncConfiguration(String syncId) {
        syncConfigManager.deleteSyncConfiguration(syncId);
    }

    @AuraEnabled
    public static List<CleverTap__Mapping__c> getExistingMappings(Id syncId) {
        return fieldMappingManager.getExistingMappings(syncId);
    }

    @AuraEnabled
    public static void updateSyncStatus(String syncId, String status) {
        syncConfigManager.updateSyncStatus(syncId, status);
    }

    @AuraEnabled
    public static String createSyncConfiguration(String syncData) {
        return syncConfigManager.createSyncConfiguration(syncData);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getSalesforceFields(String objectName) {
        return schemaUtility.getAccessibleFields(objectName);
    }

    @AuraEnabled(cacheable=true)
    public static SyncConfigurationManager.SyncConfigWrapper getSyncConfigurationById(String syncId) {
        return syncConfigManager.getSyncConfigurationById(syncId);
    }

    @AuraEnabled
    public static SyncConfigurationManager.SyncConfigWrapper updateSyncConfiguration(String syncId, String syncData) {
        return syncConfigManager.updateSyncConfiguration(syncId, syncData);
    }

    @AuraEnabled
    public static String runHistoricalSync(String syncId) {
        try {
            // Get the sync configuration
            SyncConfigurationManager.SyncConfigWrapper config = getSyncConfigurationById(syncId);
            
            if (config == null) {
                throw new AuraHandledException('Sync configuration not found');
            }
            
            if (config.status != 'Active') {
                throw new AuraHandledException('Sync configuration must be active to run historical sync');
            }
            
            // Start the batch process to sync all records
            HistoricalSyncBatch batchProcess = new HistoricalSyncBatch(config.sourceEntity, syncId);
            Database.executeBatch(batchProcess, 10); // Process 10 records at a time
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error running historical sync: ' + e.getMessage());
        }
    }
}