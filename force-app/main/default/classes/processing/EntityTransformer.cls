/**
 * @class EntityTransformer
 * @description Helper class for mapping Salesforce records to CleverTap format.
 */
public with sharing class EntityTransformer {
    /**
     * @class ConnectionMapping
     * @description Inner class to hold connection mappings between Salesforce and CleverTap
     */
    public class ConnectionMapping {
        public String connectionId { get; set; }
        public Map<String, Object> payload { get; set; }
    }
    
    /**
     * @description Maps a Salesforce record to CleverTap format
     * @param record The Salesforce record to map
     * @param recordType The type of record
     * @return The mapped record in CleverTap format
     */
    public Map<String, Object> mapToCleverTap(SObject record, String recordType) {
        if (record == null) {
            return null;
        }
        
        try {
            List<ConnectionMapping> mappings = mapToMultipleConnections(record, recordType);
            if (!mappings.isEmpty()) {
                return mappings[0].payload;
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * @description Maps a Salesforce record to CleverTap format for all active connections
     * @param record The Salesforce record to map
     * @param recordType The type of record
     * @return List of mapped records with their corresponding configurations
     */
    public List<ConnectionMapping> mapToMultipleConnections(SObject record, String recordType) {
        if (record == null) {
            return new List<ConnectionMapping>();
        }
        
        List<ConnectionMapping> allMappings = new List<ConnectionMapping>();
        
        try {   
            List<CleverTap__Sync_Configuration__c> syncConfigs = getAllSyncConfigurations(recordType);
            if (syncConfigs.isEmpty()) {
                return allMappings;
            }

            for (CleverTap__Sync_Configuration__c syncConfig : syncConfigs) {
                ConnectionMapping mapping = processConfiguration(record, recordType, syncConfig);
                if (mapping != null) {
                    allMappings.add(mapping);
                }
            }
        } catch (Exception e) {
            logError('Error mapping ' + recordType + ' to CleverTap', e);
        }
        
        return allMappings;
    }

    private ConnectionMapping processConfiguration(SObject record, String recordType, CleverTap__Sync_Configuration__c syncConfig) {
        List<CleverTap__Mapping__c> fieldMappings = getFieldMappingsForConfig(syncConfig.Id);
        if (fieldMappings.isEmpty()) {
            return null;
        }

        CleverTap__Mapping__c identityMapping = findIdentityMapping(fieldMappings);
        if (identityMapping == null) {
            return null;
        }

        String identityValue = getIdentityValue(record, identityMapping);
        
        if (String.isBlank(identityValue)) {
            return null;
        }

        Boolean isEvent = (syncConfig.CleverTap__Entity__c == 'event');
        
        String eventName = null;
        if (isEvent) {
            CleverTap__Mapping__c eventNameMapping = findEventNameMapping(fieldMappings);
            eventName = (eventNameMapping != null) ? String.valueOf(eventNameMapping.CleverTap__Salesforce_Field__c) : null;
            
            if (String.isBlank(eventName)) {
                if (recordType == 'Event') {
                    eventName = 'sf_activity_event';
                } else if (recordType == 'Task') {
                    eventName = 'sf_activity_task';
                } else {
                    eventName = 'sf_' + recordType.toLowerCase();
                }
            }
        }
        
        Map<String, Object> profileData = createProfileData(record, fieldMappings);
        
        if (recordType == 'Event' || recordType == 'Task') {
            addActivityContext(record, profileData);
        }
        
        Map<String, Object> payload = createPayload(identityValue, profileData, eventName, isEvent);
        
        ConnectionMapping mapping = new ConnectionMapping();
        mapping.connectionId = syncConfig.CleverTap__ConnectionId__c;
        mapping.payload = payload;
        return mapping;
    }

    private List<CleverTap__Sync_Configuration__c> getAllSyncConfigurations(String recordType) {
        // Enhanced security check with field-level access
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() ||
            !CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get('clevertap__salesforce_entity__c').getDescribe().isAccessible() ||
            !CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get('clevertap__status__c').getDescribe().isAccessible() || 
            !CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get('cleverTap__connectionId__c').getDescribe().isAccessible()) {
            return new List<CleverTap__Sync_Configuration__c>();
        }
        
        try {
            return [
                SELECT Id, CleverTap__Entity__c, CleverTap__ConnectionId__c
                FROM CleverTap__Sync_Configuration__c
                WHERE CleverTap__Salesforce_Entity__c = :recordType
                AND CleverTap__Status__c = 'Active'
                WITH SECURITY_ENFORCED
            ];
        } catch (System.NoAccessException e) {
            return new List<CleverTap__Sync_Configuration__c>();
        }
    }

    private List<CleverTap__Mapping__c> getFieldMappingsForConfig(Id configId) {
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() ||
            !CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().get('clevertap__sync_mapping__c').getDescribe().isAccessible()) {
            return new List<CleverTap__Mapping__c>();
        }
        
        try {
            return [
                SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                       CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
                FROM CleverTap__Mapping__c
                WHERE CleverTap__Sync_mapping__c = :configId
                WITH SECURITY_ENFORCED
            ];
        } catch (System.NoAccessException e) {
            return new List<CleverTap__Mapping__c>();
        }
    }

    private List<CleverTap__Mapping__c> getFieldMappings(String recordType) {
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() || 
            !CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap__Mapping__c>();
        }
        
        try {
            return [
                SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                       CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
                FROM CleverTap__Mapping__c
                WHERE CleverTap__Sync_mapping__c IN (
                    SELECT Id FROM CleverTap__Sync_Configuration__c 
                    WHERE CleverTap__Salesforce_Entity__c = :recordType 
                    AND CleverTap__Status__c = 'Active'
                )
                WITH SECURITY_ENFORCED
            ];
        } catch (System.NoAccessException e) {
            return new List<CleverTap__Mapping__c>();
        }
    }

    private CleverTap__Sync_Configuration__c getSyncConfiguration(String recordType) {
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return null;
        }
        
        try {
            List<CleverTap__Sync_Configuration__c> configs = [
                SELECT Id, CleverTap__Entity__c
                FROM CleverTap__Sync_Configuration__c
                WHERE CleverTap__Salesforce_Entity__c = :recordType
                AND CleverTap__Status__c = 'Active'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            return configs.isEmpty() ? null : configs[0];
        } catch (System.NoAccessException e) {
            return null;
        }
    }

    private CleverTap__Mapping__c findIdentityMapping(List<CleverTap__Mapping__c> fieldMappings) {
        for (CleverTap__Mapping__c mapping : fieldMappings) {
            if (mapping.CleverTap__Is_Mandatory__c && mapping.CleverTap__Field__c == 'Identity') {
                return mapping;
            }
        }
        return null;
    }

    private CleverTap__Mapping__c findEventNameMapping(List<CleverTap__Mapping__c> fieldMappings) {
        for (CleverTap__Mapping__c mapping : fieldMappings) {
            if (mapping.CleverTap__Is_Mandatory__c && mapping.CleverTap__Field__c == 'evtName') {
                return mapping;
            }
        }
        return null;
    }

    private String getIdentityValue(SObject record, CleverTap__Mapping__c identityMapping) {
        return String.valueOf(record.get(identityMapping.CleverTap__Salesforce_Field__c));
    }

    private Map<String, Object> createProfileData(SObject record, List<CleverTap__Mapping__c> fieldMappings) {
        Map<String, Object> profileData = new Map<String, Object>();
        ValueExtractor valueExtractor = new ValueExtractor();
        
        for (CleverTap__Mapping__c mapping : fieldMappings) {
            if (isSpecialField(mapping)) {
                continue;
            }

            String fieldName = mapping.CleverTap__Salesforce_Field__c;
            if (String.isBlank(fieldName) || !record.getPopulatedFieldsAsMap().containsKey(fieldName)) {
                continue;
            }
            
            Object fieldValue = record.get(fieldName);
            if (fieldValue == null) {
                continue;
            }

            Object convertedValue = valueExtractor.convertFieldValue(
                fieldValue, mapping.CleverTap__Data_Type__c
            );
            profileData.put(mapping.CleverTap__Field__c, convertedValue);
        }
        return profileData;
    }

    private Boolean isSpecialField(CleverTap__Mapping__c mapping) {
        return mapping.CleverTap__Is_Mandatory__c || 
               mapping.CleverTap__Field__c == 'Identity' || 
               mapping.CleverTap__Field__c == 'evtName';
    }

    private Map<String, Object> createPayload(String identityValue, Map<String, Object> profileData, 
                                              String eventName, Boolean isEvent) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('identity', identityValue);
        
        if (isEvent && String.isNotBlank(eventName)) {
            payload.put('type', 'event');
            payload.put('evtName', eventName);
            payload.put('evtData', profileData);
        } else {
            payload.put('type', 'profile');
            payload.put('profileData', profileData);
        }
        
        payload.put('$source', 'Salesforce');
        return payload;
    }
    
    private void logError(String message, Exception e) {
        // Could implement a custom logging solution here
        // For now, we're just suppressing the debug statement
        // but maintaining the method signature for future enhancement
    }

    private void addActivityContext(SObject record, Map<String, Object> profileData) {
        try {
            Id whoId = (Id)record.get('WhoId');
            if (whoId != null) {
                profileData.put('relatedToType', whoId.getSObjectType().getDescribe().getName());
            }
            
            Id whatId = (Id)record.get('WhatId');
            if (whatId != null) {
                profileData.put('relatedRecordType', whatId.getSObjectType().getDescribe().getName());
            }
        } catch (Exception e) {
            // Silently handle any errors
        }
    }
}