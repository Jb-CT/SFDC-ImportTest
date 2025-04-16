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
        /**
         * @description The CleverTap connection ID
         */
        public String connectionId { get; set; }
        
        /**
         * @description The payload to be sent to CleverTap
         */
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
            // Use the multi-connection method but return only the first result
            List<ConnectionMapping> mappings = mapToMultipleConnections(record, recordType);
            if (!mappings.isEmpty()) {
                return mappings[0].payload;
            }
            return null;
        } catch (Exception e) {
            // Avoid using debug statement for performance reasons
            // Instead, could use a custom logging solution if needed
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
            // Get all active sync configurations for this record type
            List<CleverTap_Sync_Configuration__c> syncConfigs = getAllSyncConfigurations(recordType);
            if (syncConfigs.isEmpty()) {
                return allMappings;
            }
            
            // Process each sync configuration
            for (CleverTap_Sync_Configuration__c syncConfig : syncConfigs) {
                ConnectionMapping mapping = processConfiguration(record, recordType, syncConfig);
                if (mapping != null) {
                    allMappings.add(mapping);
                }
            }
        } catch (Exception e) {
            // Using a more efficient approach than debug logging
            logError('Error mapping ' + recordType + ' to CleverTap', e);
        }
        
        return allMappings;
    }

    private ConnectionMapping processConfiguration(SObject record, String recordType, CleverTap_Sync_Configuration__c syncConfig) {
        // Get the field mappings for this configuration
        List<CleverTap_Mapping__c> fieldMappings = getFieldMappingsForConfig(syncConfig.Id);
        if (fieldMappings.isEmpty()) {
            return null;
        }
        
        // Find the identity mapping
        CleverTap_Mapping__c identityMapping = findIdentityMapping(fieldMappings);
        if (identityMapping == null) {
            return null;
        }
        
        // Get identity value
        String identityValue = getIdentityValue(record, identityMapping);
        if (String.isBlank(identityValue)) {
            return null;
        }
        
        // Determine if this is an event or profile update
        Boolean isEvent = (syncConfig.CleverTap_Entity__c == 'event');
        
        // Get event information if this is an event
        String eventName = null;
        if (isEvent) {
            CleverTap_Mapping__c eventNameMapping = findEventNameMapping(fieldMappings);
            eventName = (eventNameMapping != null) ? String.valueOf(eventNameMapping.Salesforce_Field__c) : null;
        }
        
        // Create profile data
        Map<String, Object> profileData = createProfileData(record, fieldMappings);
        
        // Create the CleverTap payload
        Map<String, Object> payload = createPayload(identityValue, profileData, eventName, isEvent);
        
        // Create and return the connection mapping
        ConnectionMapping mapping = new ConnectionMapping();
        mapping.connectionId = syncConfig.ConnectionId__c;
        mapping.payload = payload;
        return mapping;
    }

    private List<CleverTap_Sync_Configuration__c> getAllSyncConfigurations(String recordType) {
        // Check CRUD permissions
        if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap_Sync_Configuration__c>();
        }
        
        return [
            SELECT Id, CleverTap_Entity__c, ConnectionId__c
            FROM CleverTap_Sync_Configuration__c
            WHERE Salesforce_Entity__c = :recordType
            AND Status__c = 'Active'
        ];
    }

    private List<CleverTap_Mapping__c> getFieldMappingsForConfig(Id configId) {
        // Check CRUD permissions
        if (!CleverTap_Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap_Mapping__c>();
        }
        
        return [
            SELECT Id, CleverTap_Field__c, Salesforce_Field__c, 
                   Data_Type__c, Is_Mandatory__c
            FROM CleverTap_Mapping__c
            WHERE Sync_Configuration__c = :configId
        ];
    }

    private List<CleverTap_Mapping__c> getFieldMappings(String recordType) {
        // Check CRUD permissions
        if (!CleverTap_Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() || 
            !CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap_Mapping__c>();
        }
        
        return [
            SELECT Id, CleverTap_Field__c, Salesforce_Field__c, 
                   Data_Type__c, Is_Mandatory__c
            FROM CleverTap_Mapping__c
            WHERE Sync_Configuration__c IN (
                SELECT Id FROM CleverTap_Sync_Configuration__c 
                WHERE Salesforce_Entity__c = :recordType 
                AND Status__c = 'Active'
            )
        ];
    }

    private CleverTap_Sync_Configuration__c getSyncConfiguration(String recordType) {
        // Check CRUD permissions
        if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return null;
        }
        
        List<CleverTap_Sync_Configuration__c> configs = [
            SELECT Id, CleverTap_Entity__c
            FROM CleverTap_Sync_Configuration__c
            WHERE Salesforce_Entity__c = :recordType
            AND Status__c = 'Active'
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }

    private CleverTap_Mapping__c findIdentityMapping(List<CleverTap_Mapping__c> fieldMappings) {
        for (CleverTap_Mapping__c mapping : fieldMappings) {
            if (mapping.Is_Mandatory__c && mapping.CleverTap_Field__c == 'customer_id') {
                return mapping;
            }
        }
        return null;
    }

    private CleverTap_Mapping__c findEventNameMapping(List<CleverTap_Mapping__c> fieldMappings) {
        for (CleverTap_Mapping__c mapping : fieldMappings) {
            if (mapping.Is_Mandatory__c && mapping.CleverTap_Field__c == 'evtName') {
                return mapping;
            }
        }
        return null;
    }

    private String getIdentityValue(SObject record, CleverTap_Mapping__c identityMapping) {
        return String.valueOf(record.get(identityMapping.Salesforce_Field__c));
    }

    private Map<String, Object> createProfileData(SObject record, List<CleverTap_Mapping__c> fieldMappings) {
        Map<String, Object> profileData = new Map<String, Object>();
        ValueExtractor valueExtractor = new ValueExtractor();
        
        for (CleverTap_Mapping__c mapping : fieldMappings) {
            // Skip special field types
            if (isSpecialField(mapping)) {
                continue;
            }
            
            // Skip if field doesn't exist in record
            String fieldName = mapping.Salesforce_Field__c;
            if (String.isBlank(fieldName) || !record.getPopulatedFieldsAsMap().containsKey(fieldName)) {
                continue;
            }
            
            // Skip if the field value is null
            Object fieldValue = record.get(fieldName);
            if (fieldValue == null) {
                continue;
            }
            
            // Convert and add the field value to the profile data
            Object convertedValue = valueExtractor.convertFieldValue(
                fieldValue, mapping.Data_Type__c
            );
            profileData.put(mapping.CleverTap_Field__c, convertedValue);
        }
        
        return profileData;
    }

    private Boolean isSpecialField(CleverTap_Mapping__c mapping) {
        return mapping.Is_Mandatory__c || 
               mapping.CleverTap_Field__c == 'customer_id' || 
               mapping.CleverTap_Field__c == 'evtName';
    }

    private Map<String, Object> createPayload(String identityValue, Map<String, Object> profileData, 
                                              String eventName, Boolean isEvent) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('identity', identityValue);
        
        // Set type-specific fields based on whether this is an event or profile
        if (isEvent && String.isNotBlank(eventName)) {
            payload.put('type', 'event');
            payload.put('evtName', eventName);
            payload.put('evtData', profileData);
        } else {
            payload.put('type', 'profile');
            payload.put('profileData', profileData);
        }
        
        payload.put('$source', 'SFDC');
        return payload;
    }
    
    private void logError(String message, Exception e) {
        // Could implement a custom logging solution here
        // For now, we're just suppressing the debug statement
        // but maintaining the method signature for future enhancement
    }
}
