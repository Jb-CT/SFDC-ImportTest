/**
 * @class FieldMappingManager
 * @description Manager class for handling field mapping operations.
 * Handles CRUD operations for CleverTap__Mapping__c records.
 */
public with sharing class FieldMappingManager {
    /**
     * @description Gets existing field mappings for a sync configuration
     * @param syncId The ID of the sync configuration
     * @return List of field mappings
     * @throws AuraHandledException If there is an error accessing the mappings
     */
    public List<CleverTap__Mapping__c> getExistingMappings(Id syncId) {
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            throw new AuraHandledException('You do not have access to field mappings');
        }
        
        return [
            SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                   CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
            FROM CleverTap__Mapping__c
            WHERE CleverTap__Sync_mapping__c = :syncId
        ];
    }

    public void saveFieldMappings(String mappingData) {
        Savepoint sp = Database.setSavepoint();
        try {
            checkMappingPermissions();
            validateMappingData(mappingData);
            
            // Parse the mapping data
            Map<String, Object> mappingsMap = parseMappingJson(mappingData);
            Id syncId = validateSyncId(mappingsMap);
            List<Object> mappingsObj = validateMappingsList(mappingsMap);

            // Process the mappings
            processFieldMappings(syncId, mappingsObj);
            
        } catch (Exception e) {
            // Rollback on error
            Database.rollback(sp);
            throw new AuraHandledException('Error saving mappings: ' + e.getMessage());
        }
    }

    private void checkMappingPermissions() {
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isCreateable() ||
            !CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isDeletable()) {
            throw new AuraHandledException('Insufficient permissions to manage field mappings');
        }
    }

    private void validateMappingData(String mappingData) {
        if (String.isBlank(mappingData)) {
            throw new AuraHandledException('Mapping data cannot be empty');
        }
    }

    private Map<String, Object> parseMappingJson(String mappingData) {
        try {
            return (Map<String, Object>)JSON.deserializeUntyped(mappingData);
        } catch (Exception e) {
            throw new AuraHandledException('Invalid JSON format: ' + e.getMessage());
        }
    }

    private Id validateSyncId(Map<String, Object> mappingsMap) {
        try {
            Id syncId = (Id)mappingsMap.get('syncId');
            if (syncId == null) {
                throw new AuraHandledException('SyncId is required');
            }
            return syncId;
        } catch (Exception e) {
            throw new AuraHandledException('Invalid syncId: ' + e.getMessage());
        }
    }

    private List<Object> validateMappingsList(Map<String, Object> mappingsMap) {
        List<Object> mappingsObj = (List<Object>)mappingsMap.get('mappings');
        if (mappingsObj == null || mappingsObj.isEmpty()) {
            throw new AuraHandledException('No mappings provided');
        }
        return mappingsObj;
    }

    private void processFieldMappings(Id syncId, List<Object> mappingsObj) {
        deleteExistingMappings(syncId);

        List<CleverTap__Mapping__c> newMappings = createNewMappings(syncId, mappingsObj);

        insertMappings(newMappings);
    }

    private void deleteExistingMappings(Id syncId) {
        try {
            delete [SELECT Id FROM CleverTap__Mapping__c WHERE CleverTap__Sync_mapping__c = :syncId];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting existing mappings: ' + e.getMessage());
        }
    }

    private List<CleverTap__Mapping__c> createNewMappings(Id syncId, List<Object> mappingsObj) {
        List<CleverTap__Mapping__c> newMappings = new List<CleverTap__Mapping__c>();
        
        for(Object mappingObj : mappingsObj) {
            Map<String, Object> mapping = (Map<String, Object>)mappingObj;
            CleverTap__Mapping__c newMapping = createMappingRecord(syncId, mapping);
            newMappings.add(newMapping);
        }
        
        return newMappings;
    }

    private CleverTap__Mapping__c createMappingRecord(Id syncId, Map<String, Object> mapping) {
        // Validate required fields
        String targetField = (String)mapping.get('CleverTap__Field__c');
        String sourceField = (String)mapping.get('CleverTap__Salesforce_Field__c');
        
        if (String.isBlank(targetField)) {
            throw new AuraHandledException('Target field name is required');
        }
        if (String.isBlank(sourceField)) {
            throw new AuraHandledException('Source field name is required');
        }

        return new CleverTap__Mapping__c(
            CleverTap__Sync_mapping__c = syncId,
            CleverTap__Field__c = targetField,
            CleverTap__Salesforce_Field__c = sourceField,
            CleverTap__Data_Type__c = (String)mapping.get('CleverTap__Data_Type__c'),
            CleverTap__Is_Mandatory__c = (Boolean)mapping.get('CleverTap__Is_Mandatory__c')
        );
    }

    private void insertMappings(List<CleverTap__Mapping__c> newMappings) {
        try {
            insert newMappings;
        } catch (Exception e) {
            throw new AuraHandledException('Error inserting new mappings: ' + e.getMessage());
        }
    }
}