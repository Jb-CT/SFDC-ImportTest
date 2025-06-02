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
            List<CleverTap__Sync_Configuration__c> syncConfigs = getAllSyncConfigurations(recordType);
            if (syncConfigs.isEmpty()) {
                return allMappings;
            }
            
            // Process each sync configuration
            for (CleverTap__Sync_Configuration__c syncConfig : syncConfigs) {
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

    private ConnectionMapping processConfiguration(SObject record, String recordType, CleverTap__Sync_Configuration__c syncConfig) {
        List<CleverTap__Mapping__c> fieldMappings = getFieldMappingsForConfig(syncConfig.Id);
        if (fieldMappings.isEmpty()) {
            return null;
        }

        CleverTap__Mapping__c identityMapping = findIdentityMapping(fieldMappings);
        if (identityMapping == null) {
            return null;
        }

        String identityValue = null;

        if (recordType == 'Event' || recordType == 'Task') {
            identityValue = getActivityIdentity(record, recordType);
        }
        else if (recordType == 'CampaignMember') {
            identityValue = getCampaignMemberIdentity((CampaignMember)record);
        }
        else {
            identityValue = getIdentityValue(record, identityMapping);
        }
        
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
        // Check CRUD permissions
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap__Sync_Configuration__c>();
        }
        
        return [
            SELECT Id, CleverTap__Entity__c, CleverTap__ConnectionId__c
            FROM CleverTap__Sync_Configuration__c
            WHERE CleverTap__Salesforce_Entity__c = :recordType
            AND CleverTap__Status__c = 'Active'
        ];
    }

    private List<CleverTap__Mapping__c> getFieldMappingsForConfig(Id configId) {
        // Check CRUD permissions
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap__Mapping__c>();
        }
        
        return [
            SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                   CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
            FROM CleverTap__Mapping__c
            WHERE CleverTap__Sync_mapping__c = :configId
        ];
    }

    private List<CleverTap__Mapping__c> getFieldMappings(String recordType) {
        // Check CRUD permissions
        if (!CleverTap__Mapping__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() || 
            !CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return new List<CleverTap__Mapping__c>();
        }
        
        return [
            SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                   CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
            FROM CleverTap__Mapping__c
            WHERE CleverTap__Sync_mapping__c IN (
                SELECT Id FROM CleverTap__Sync_Configuration__c 
                WHERE CleverTap__Salesforce_Entity__c = :recordType 
                AND CleverTap__Status__c = 'Active'
            )
        ];
    }

    private CleverTap__Sync_Configuration__c getSyncConfiguration(String recordType) {
        // Check CRUD permissions
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return null;
        }
        
        List<CleverTap__Sync_Configuration__c> configs = [
            SELECT Id, CleverTap__Entity__c
            FROM CleverTap__Sync_Configuration__c
            WHERE CleverTap__Salesforce_Entity__c = :recordType
            AND CleverTap__Status__c = 'Active'
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
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
            // Skip special field types
            if (isSpecialField(mapping)) {
                continue;
            }
            
            // Skip if field doesn't exist in record
            String fieldName = mapping.CleverTap__Salesforce_Field__c;
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
        
        // Set type-specific fields based on whether this is an event or profile
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

    private String getActivityIdentity(SObject record, String recordType) {
        String identityValue = null;
        
        try {
            Id whoId = (Id)record.get('WhoId');
            
            if (whoId != null) {
                String whoObjectType = whoId.getSObjectType().getDescribe().getName();
                
                if (whoObjectType == 'Contact') {
                    if (Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
                        Contact.Email.getDescribe().isAccessible()) {
                        List<Contact> contacts = [SELECT Email FROM Contact WHERE Id = :whoId LIMIT 1];
                        if (!contacts.isEmpty() && contacts[0].Email != null) {
                            identityValue = contacts[0].Email;
                        }
                    }
                } else if (whoObjectType == 'Lead') {
                    // Query Lead email with security checks
                    if (Lead.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
                        Lead.Email.getDescribe().isAccessible()) {
                        List<Lead> leads = [SELECT Email FROM Lead WHERE Id = :whoId LIMIT 1];
                        if (!leads.isEmpty() && leads[0].Email != null) {
                            identityValue = leads[0].Email;
                        }
                    }
                }
            }

            if (String.isBlank(identityValue)) {
                Id whatId = (Id)record.get('WhatId');
                if (whatId != null) {
                    String whatObjectType = whatId.getSObjectType().getDescribe().getName();
                    
                    if (whatObjectType == 'Account') {
                        // Use Account Name as identity
                        if (Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
                            Account.Name.getDescribe().isAccessible()) {
                            List<Account> accounts = [SELECT Name FROM Account WHERE Id = :whatId LIMIT 1];
                            if (!accounts.isEmpty()) {
                                identityValue = 'account_' + accounts[0].Name;
                            }
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            logError('Error getting activity identity for ' + recordType, e);
        }
        
        return identityValue;
    }

    private String getCampaignMemberIdentity(CampaignMember campaignMember) {
        String identityValue = null;
        
        try {
            // Check if it's a Contact
            if (campaignMember.ContactId != null) {
                if (Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
                    Contact.Email.getDescribe().isAccessible()) {
                    List<Contact> contacts = [SELECT Email FROM Contact WHERE Id = :campaignMember.ContactId LIMIT 1];
                    if (!contacts.isEmpty() && contacts[0].Email != null) {
                        identityValue = contacts[0].Email;
                    }
                }
            }
            else if (campaignMember.LeadId != null) {
                if (Lead.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible() &&
                    Lead.Email.getDescribe().isAccessible()) {
                    List<Lead> leads = [SELECT Email FROM Lead WHERE Id = :campaignMember.LeadId LIMIT 1];
                    if (!leads.isEmpty() && leads[0].Email != null) {
                        identityValue = leads[0].Email;
                    }
                }
            }
        } catch (Exception e) {
            logError('Error getting campaign member identity', e);
        }
        
        return identityValue;
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
