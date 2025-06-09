/**
 * @class SyncConfigurationManager
 * @description Manager class for handling sync configuration operations.
 * Handles CRUD operations for CleverTap__Sync_Configuration__c records.
 */
public with sharing class SyncConfigurationManager {
    /**
     * @class SyncConfigWrapper
     * @description Wrapper class for CleverTap__Sync_Configuration__c objects
     */
    public class SyncConfigWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String syncType { get; set; }
        @AuraEnabled public String sourceEntity { get; set; }
        @AuraEnabled public String targetEntity { get; set; }
        @AuraEnabled public String status { get; set; }

        public SyncConfigWrapper(CleverTap__Sync_Configuration__c config) {
            this.id = config.Id;
            this.name = config.Name;
            this.syncType = config.CleverTap__Sync_Type__c;
            this.sourceEntity = config.CleverTap__Salesforce_Entity__c;
            this.targetEntity = config.CleverTap__Entity__c;
            this.status = config.CleverTap__Status__c;
        }
    }

    public List<SyncConfigWrapper> getSyncConfigurations(String connectionId) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                throw new AuraHandledException('You do not have access to sync configurations');
            }
            
            List<CleverTap__Sync_Configuration__c> configs = [
                SELECT Id, Name, CleverTap__Sync_Type__c, 
                       CleverTap__Salesforce_Entity__c, CleverTap__Entity__c, 
                       CleverTap__Status__c, CleverTap__ConnectionId__c
                FROM CleverTap__Sync_Configuration__c
                WHERE CleverTap__ConnectionId__c = :connectionId
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
            ];
            
            return wrapConfigurations(configs);
            
        } catch (System.QueryException e) {
            throw new AuraHandledException('Insufficient permissions to access the requested fields: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sync configurations: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to convert configurations to wrappers
     * @param configs List of CleverTap__Sync_Configuration__c records
     * @return List of sync configuration wrappers
     */
    private List<SyncConfigWrapper> wrapConfigurations(List<CleverTap__Sync_Configuration__c> configs) {
        List<SyncConfigWrapper> wrappers = new List<SyncConfigWrapper>();
        for (CleverTap__Sync_Configuration__c config : configs) {
            wrappers.add(new SyncConfigWrapper(config));
        }
        return wrappers;
    }

    public SyncConfigWrapper getSyncConfigurationById(String syncId) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
                throw new AuraHandledException('You do not have access to sync configurations');
            }
            
            CleverTap__Sync_Configuration__c config = [
                SELECT Id, Name, CleverTap__Sync_Type__c, 
                       CleverTap__Salesforce_Entity__c, CleverTap__Entity__c, 
                       CleverTap__Status__c
                FROM CleverTap__Sync_Configuration__c
                WHERE Id = :syncId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return new SyncConfigWrapper(config);
        } catch (System.QueryException e) {
            throw new AuraHandledException('Insufficient permissions to access the requested fields: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching sync configuration: ' + e.getMessage());
        }
    }

    public String createSyncConfiguration(String syncData) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable()) {
                throw new AuraHandledException('You do not have permission to create configurations');
            }
            
            Map<String, Object> syncMap = (Map<String, Object>) JSON.deserializeUntyped(syncData);
            
            CleverTap__Sync_Configuration__c syncConfig = new CleverTap__Sync_Configuration__c(
                Name = (String) syncMap.get('name'),
                CleverTap__Sync_Type__c = (String) syncMap.get('syncType'),
                CleverTap__Salesforce_Entity__c = (String) syncMap.get('sourceEntity'),
                CleverTap__Entity__c = (String) syncMap.get('targetEntity'),
                CleverTap__ConnectionId__c = (String) syncMap.get('connectionId'),
                CleverTap__Status__c = 'Active'
            );
            
            Database.insert(syncConfig, AccessLevel.USER_MODE);
            return syncConfig.Id;
            
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('Access denied: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error creating sync configuration: ' + e.getMessage());
        }
    }

    public SyncConfigWrapper updateSyncConfiguration(String syncId, String syncData) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update configurations');
            }

            if (!Schema.SObjectType.CleverTap__Sync_Configuration__c.fields.Name.isUpdateable() ||
                !Schema.SObjectType.CleverTap__Sync_Configuration__c.fields.CleverTap__Sync_Type__c.isUpdateable() ||
                !Schema.SObjectType.CleverTap__Sync_Configuration__c.fields.CleverTap__Salesforce_Entity__c.isUpdateable() ||
                !Schema.SObjectType.CleverTap__Sync_Configuration__c.fields.CleverTap__Entity__c.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update some fields');
            }
            
            Map<String, Object> syncMap = (Map<String, Object>) JSON.deserializeUntyped(syncData);
            
            CleverTap__Sync_Configuration__c syncConfig = [
                SELECT Id FROM CleverTap__Sync_Configuration__c 
                WHERE Id = :syncId 
                LIMIT 1
            ];
            
            syncConfig.Name = (String) syncMap.get('name');
            syncConfig.CleverTap__Sync_Type__c = (String) syncMap.get('syncType');
            syncConfig.CleverTap__Salesforce_Entity__c = (String) syncMap.get('sourceEntity');
            syncConfig.CleverTap__Entity__c = (String) syncMap.get('targetEntity');
            
            Database.update(syncConfig, AccessLevel.USER_MODE);
            
            return getSyncConfigurationById(syncId);
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('Access denied: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sync configuration: ' + e.getMessage());
        }
    }

    public void updateSyncStatus(String syncId, String status) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update configurations');
            }
            
            if (!Schema.SObjectType.CleverTap__Sync_Configuration__c.fields.CleverTap__Status__c.isUpdateable()) {
                throw new AuraHandledException('You do not have permission to update the Status field');
            }
            
            CleverTap__Sync_Configuration__c config = [
                SELECT Id, CleverTap__Status__c 
                FROM CleverTap__Sync_Configuration__c 
                WHERE Id = :syncId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            config.CleverTap__Status__c = status;
            
            Database.update(config, AccessLevel.USER_MODE);
            
        } catch (System.QueryException e) {
            throw new AuraHandledException('Insufficient permissions to access the requested fields: ' + e.getMessage());
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('Access denied: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error updating sync status: ' + e.getMessage());
        }
    }

    public void deleteSyncConfiguration(String syncId) {
        try {
            if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
                throw new AuraHandledException('You do not have permission to delete configurations');
            }
            
            CleverTap__Sync_Configuration__c config = [
                SELECT Id 
                FROM CleverTap__Sync_Configuration__c 
                WHERE Id = :syncId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            Database.delete(config, AccessLevel.USER_MODE);
            
        } catch (System.QueryException e) {
            throw new AuraHandledException('Insufficient permissions to access configuration: ' + e.getMessage());
        } catch (System.NoAccessException e) {
            throw new AuraHandledException('Access denied: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting sync configuration: ' + e.getMessage());
        }
    }
}