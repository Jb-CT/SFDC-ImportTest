/**
 * @class SyncConfigurationManager
 * @description Manager class for handling sync configuration operations.
 * Handles CRUD operations for CleverTap_Sync_Configuration__c records.
 */
public with sharing class SyncConfigurationManager {
    /**
     * @class SyncConfigWrapper
     * @description Wrapper class for CleverTap_Sync_Configuration__c objects
     */
    public class SyncConfigWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String syncType { get; set; }
        @AuraEnabled public String sourceEntity { get; set; }
        @AuraEnabled public String targetEntity { get; set; }
        @AuraEnabled public String status { get; set; }

        public SyncConfigWrapper(CleverTap_Sync_Configuration__c config) {
            this.id = config.Id;
            this.name = config.Name;
            this.syncType = config.Sync_Type__c;
            this.sourceEntity = config.Salesforce_Entity__c;
            this.targetEntity = config.CleverTap_Entity__c;
            this.status = config.Status__c;
        }
    }

    public List<SyncConfigWrapper> getSyncConfigurations(String connectionId) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                throw new AuraHandledException('You do not have access to sync configurations');
            }
            
            List<CleverTap_Sync_Configuration__c> configs = [
                SELECT Id, Name, Sync_Type__c, 
                       Salesforce_Entity__c, CleverTap_Entity__c, 
                       Status__c, ConnectionId__c
                FROM CleverTap_Sync_Configuration__c
                WHERE ConnectionId__c = :connectionId
                ORDER BY CreatedDate DESC
            ];
            
            return wrapConfigurations(configs);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sync configurations: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to convert configurations to wrappers
     * @param configs List of CleverTap_Sync_Configuration__c records
     * @return List of sync configuration wrappers
     */
    private List<SyncConfigWrapper> wrapConfigurations(List<CleverTap_Sync_Configuration__c> configs) {
        List<SyncConfigWrapper> wrappers = new List<SyncConfigWrapper>();
        for (CleverTap_Sync_Configuration__c config : configs) {
            wrappers.add(new SyncConfigWrapper(config));
        }
        return wrappers;
    }

    public SyncConfigWrapper getSyncConfigurationById(String syncId) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                throw new AuraHandledException('You do not have access to sync configurations');
            }
            
            CleverTap_Sync_Configuration__c config = [
                SELECT Id, Name, Sync_Type__c, 
                       Salesforce_Entity__c, CleverTap_Entity__c, 
                       Status__c
                FROM CleverTap_Sync_Configuration__c
                WHERE Id = :syncId
                LIMIT 1
            ];
            
            return new SyncConfigWrapper(config);
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sync configuration: ' + e.getMessage());
        }
    }

    public String createSyncConfiguration(String syncData) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
                throw new AuraHandledException('You do not have permission to create configurations');
            }
            
            Map<String, Object> syncMap = (Map<String, Object>) JSON.deserializeUntyped(syncData);
            
            CleverTap_Sync_Configuration__c syncConfig = new CleverTap_Sync_Configuration__c(
                Name = (String) syncMap.get('name'),
                Sync_Type__c = (String) syncMap.get('syncType'),
                Salesforce_Entity__c = (String) syncMap.get('sourceEntity'),
                CleverTap_Entity__c = (String) syncMap.get('targetEntity'),
                ConnectionId__c = (String) syncMap.get('connectionId'),
                Status__c = 'Active'
            );
            
            insert syncConfig;
            return syncConfig.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating sync configuration: ' + e.getMessage());
        }
    }

    public SyncConfigWrapper updateSyncConfiguration(String syncId, String syncData) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update configurations');
            }
            
            Map<String, Object> syncMap = (Map<String, Object>) JSON.deserializeUntyped(syncData);
            
            CleverTap_Sync_Configuration__c syncConfig = [
                SELECT Id FROM CleverTap_Sync_Configuration__c 
                WHERE Id = :syncId 
                LIMIT 1
            ];
            
            syncConfig.Name = (String) syncMap.get('name');
            syncConfig.Sync_Type__c = (String) syncMap.get('syncType');
            syncConfig.Salesforce_Entity__c = (String) syncMap.get('sourceEntity');
            syncConfig.CleverTap_Entity__c = (String) syncMap.get('targetEntity');
            
            update syncConfig;
            
            // Return the updated record
            return getSyncConfigurationById(syncId);
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sync configuration: ' + e.getMessage());
        }
    }

    public void updateSyncStatus(String syncId, String status) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update configurations');
            }
            
            CleverTap_Sync_Configuration__c config = [
                SELECT Id, Status__c FROM CleverTap_Sync_Configuration__c WHERE Id = :syncId LIMIT 1
            ];
            config.Status__c = status;
            update config;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sync status: ' + e.getMessage());
        }
    }

    public void deleteSyncConfiguration(String syncId) {
        try {
            if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete configurations');
            }
            
            CleverTap_Sync_Configuration__c config = [
                SELECT Id FROM CleverTap_Sync_Configuration__c WHERE Id = :syncId LIMIT 1
            ];
            delete config;
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting sync configuration: ' + e.getMessage());
        }
    }
}