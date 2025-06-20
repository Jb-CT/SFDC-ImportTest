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

    /**
     * @description Validates that the current user has CleverTap integration access
     * @throws AuraHandledException if user lacks required permissions
     */
    private static void validateCleverTapAccess() {
        List<PermissionSetAssignment> assignments = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :UserInfo.getUserId() 
            AND PermissionSet.Name = 'CleverTapIntegrationAccess' 
            LIMIT 1
        ];
        
        if (assignments.isEmpty()) {
            throw new AuraHandledException('You do not have permission to perform CleverTap integration operations.');
        }
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
        validateCleverTapAccess();
        fieldMappingManager.saveFieldMappings(mappingData);
    }

    @AuraEnabled
    public static void deleteSyncConfiguration(String syncId) {
        validateCleverTapAccess();
        syncConfigManager.deleteSyncConfiguration(syncId);
    }

    @AuraEnabled
    public static List<CleverTap__Mapping__c> getExistingMappings(Id syncId) {
        return fieldMappingManager.getExistingMappings(syncId);
    }

    @AuraEnabled
    public static void updateSyncStatus(String syncId, String status) {
        validateCleverTapAccess();
        syncConfigManager.updateSyncStatus(syncId, status);
    }

    @AuraEnabled
    public static String createSyncConfiguration(String syncData) {
        validateCleverTapAccess();
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
        validateCleverTapAccess();
        return syncConfigManager.updateSyncConfiguration(syncId, syncData);
    }

    @AuraEnabled
    public static String runHistoricalSync(String syncId) {
        validateCleverTapAccess();
        try {
            SyncConfigurationManager.SyncConfigWrapper config = getSyncConfigurationById(syncId);
            
            if (config == null) {
                throw new AuraHandledException('Sync configuration not found');
            }
            
            if (config.status != 'Active') {
                throw new AuraHandledException('Sync configuration must be active to run historical sync');
            }

            HistoricalSyncBatch batchProcess = new HistoricalSyncBatch(config.sourceEntity, syncId);
            Database.executeBatch(batchProcess, 65); 
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error running historical sync: ' + e.getMessage());
        }
    }
}