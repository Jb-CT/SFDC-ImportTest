/**
 * @class HistoricalSyncBatch
 * @description Batch class for handling historical data sync between Salesforce and CleverTap.
 */
public with sharing class HistoricalSyncBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {
    private final String objectName;
    private final String syncConfigId;

    private Integer recordsProcessed = 0;
    private Integer recordsSuccess = 0;
    private Integer recordsFailed = 0;
    private List<SerializableEventData> eventLogs = new List<SerializableEventData>();
    
    private final String profileApiPath = '/1/upload';
    private final String eventApiPath = '/1/upload';

    private CleverTap__Sync_Configuration__c cachedSyncConfig;
    private List<CleverTap__Mapping__c> cachedFieldMappings;
    private Map<String, CleverTap__Mapping__c> specialMappings;
    
    /**
     * @description Constructor for the batch class
     * @param objectName The name of the object to sync
     * @param syncConfigId The ID of the sync configuration
     */
    public HistoricalSyncBatch(String objectName, String syncConfigId) {
        this.objectName = objectName;
        this.syncConfigId = syncConfigId;
        this.specialMappings = new Map<String, CleverTap__Mapping__c>();
    }
    
    /**
     * @description Query method to retrieve all records of the specified object type
     * with all mapped fields
     * @param bc The batch context
     * @return Database.QueryLocator The query locator for all records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> fieldsToQuery = getFieldsFromMappings();

        String query = buildQueryWithFields(fieldsToQuery);

        return Database.getQueryLocator(query);
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private Set<String> getFieldsFromMappings() {
        Set<String> fields = new Set<String>{'Id'}; 
        
        try {
            List<CleverTap__Mapping__c> mappings = getFieldMappings();
            
            for (CleverTap__Mapping__c mapping : mappings) {
                if (mapping.CleverTap__Field__c == 'evtName') {
                    continue;
                }

                if (String.isBlank(mapping.CleverTap__Salesforce_Field__c)) {
                    continue;
                }

                if (isValidField(mapping.CleverTap__Salesforce_Field__c, objectName)) {
                    fields.add(mapping.CleverTap__Salesforce_Field__c);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching field mappings: ' + e.getMessage());
        }
        
        return fields;
    }

    private Boolean isValidField(String fieldName, String objectType) {
        if (fieldName.contains('__c') || fieldName.contains('.')) {
            return true;
        }

        return isStandardField(fieldName, objectType);
    }

    private Boolean isStandardField(String fieldName, String objectType) {
        Set<String> commonFields = new Set<String>{'Id', 'Name', 'CreatedDate', 'LastModifiedDate', 'OwnerId'};
        if (commonFields.contains(fieldName)) {
            return true;
        }

        Map<String, Set<String>> objectFields = getObjectSpecificFields();
        
        return objectFields.containsKey(objectType) && 
               objectFields.get(objectType).contains(fieldName);
    }

    private Map<String, Set<String>> getObjectSpecificFields() {
        return new Map<String, Set<String>>{
            'Lead' => new Set<String>{'Email', 'FirstName', 'LastName', 'Company', 'Status', 'Phone'},
            'Contact' => new Set<String>{'Email', 'FirstName', 'LastName', 'AccountId', 'Phone'},
            'Account' => new Set<String>{'Industry', 'Type', 'BillingCity', 'Phone'},
            'Opportunity' => new Set<String>{'Amount', 'CloseDate', 'StageName', 'AccountId'}
        };
    }

    private String buildQueryWithFields(Set<String> fields) {
        String fieldList = String.join(new List<String>(fields), ', ');
        return 'SELECT ' + fieldList + ' FROM ' + objectName;
    }
    
    /**
     * @description Execute method to process records in batches
     * @param bc The batch context
     * @param scope The list of records to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        CleverTap__Sync_Configuration__c syncConfig = getActiveSyncConfig();
        if (syncConfig == null) {
            return;
        }

        Map<String, String> credentials = getCredentials(syncConfig.CleverTap__ConnectionId__c);
        if (credentials == null || credentials.isEmpty()) {
            return;
        }
        
        for (SObject record : scope) {
            processRecord(record, syncConfig, credentials);
        }
    }

    private void processRecord(SObject record, CleverTap__Sync_Configuration__c syncConfig, Map<String, String> credentials) {
        try {
            recordsProcessed++;

            Map<String, Object> payload = mapRecord(record, syncConfig);
            if (payload == null) {
                return;
            }

            String requestBody = getRequestBody(payload);
            HttpResponse response = sendToCleverTap(credentials, payload, syncConfig.CleverTap__Entity__c);

            logResult(record, response, requestBody);
        } catch (Exception e) {
            logError(record, e);
        }
    }

    private void logResult(SObject record, HttpResponse response, String requestBody) {
        if (response != null && response.getStatusCode() == 200) {
            recordsSuccess++;
        } else {
            recordsFailed++;
        }

        SerializableEventData eventData = new SerializableEventData();
        eventData.recordId = record.Id;
        eventData.recordType = objectName;
        
        if (response != null) {
            eventData.statusCode = response.getStatusCode();
            eventData.responseBody = response.getBody();
        } else {
            eventData.statusCode = 0;
            eventData.responseBody = 'No response';
        }
        
        eventData.requestBody = requestBody;
        eventLogs.add(eventData);
    }

    private void logError(SObject record, Exception e) {
        recordsFailed++;

        SerializableEventData eventData = new SerializableEventData();
        eventData.recordId = record.Id;
        eventData.recordType = objectName;
        eventData.statusCode = 0;
        eventData.responseBody = 'Error: ' + e.getMessage();
        eventData.requestBody = 'Exception during processing';
        
        eventLogs.add(eventData);
    }

    private CleverTap__Sync_Configuration__c getActiveSyncConfig() {
        if (cachedSyncConfig != null) {
            return cachedSyncConfig;
        }
        
        List<CleverTap__Sync_Configuration__c> syncConfigs = [
            SELECT Id, CleverTap__Entity__c, CleverTap__ConnectionId__c
            FROM CleverTap__Sync_Configuration__c
            WHERE CleverTap__Salesforce_Entity__c = :objectName
            AND CleverTap__Status__c = 'Active'
            AND Id = :syncConfigId
            LIMIT 1
        ];
        
        cachedSyncConfig = syncConfigs.isEmpty() ? null : syncConfigs[0];
        return cachedSyncConfig;
    }

    private List<CleverTap__Mapping__c> getFieldMappings() {
        if (cachedFieldMappings != null) {
            return cachedFieldMappings;
        }
        
        cachedFieldMappings = [
            SELECT Id, CleverTap__Field__c, CleverTap__Salesforce_Field__c, 
                CleverTap__Data_Type__c, CleverTap__Is_Mandatory__c
            FROM CleverTap__Mapping__c
            WHERE CleverTap__Sync_mapping__c = :syncConfigId
        ];

        for (CleverTap__Mapping__c mapping : cachedFieldMappings) {
            if (mapping.CleverTap__Is_Mandatory__c && mapping.CleverTap__Field__c == 'customer_id') {
                specialMappings.put('customer_id', mapping);
            } else if (mapping.CleverTap__Field__c == 'evtName') {
                specialMappings.put('evtName', mapping);
            }
        }
        
        return cachedFieldMappings;
    }

    private Map<String, Object> mapRecord(SObject record, CleverTap__Sync_Configuration__c syncConfig) {
        try {
            List<CleverTap__Mapping__c> fieldMappings = getFieldMappings();
            if (fieldMappings.isEmpty()) {
                return null;
            }

            CleverTap__Mapping__c identityMapping = specialMappings.get('customer_id');
            if (identityMapping == null) {
                return null;
            }

            Object idValue = record.get(identityMapping.CleverTap__Salesforce_Field__c);
            if (idValue == null) {
                return null;
            }
            
            String identityValue = String.valueOf(idValue);

            Map<String, Object> profileData = createProfileData(record, fieldMappings);

            return createFinalPayload(identityValue, profileData, syncConfig.CleverTap__Entity__c);
        } catch (Exception e) {
            return null;
        }
    }

    private Map<String, Object> createProfileData(SObject record, List<CleverTap__Mapping__c> fieldMappings) {
        ValueExtractor valueExtractor = new ValueExtractor();
        Map<String, Object> profileData = new Map<String, Object>();
        
        for (CleverTap__Mapping__c mapping : fieldMappings) {
            if (mapping.CleverTap__Is_Mandatory__c || 
                mapping.CleverTap__Field__c == 'customer_id' ||
                mapping.CleverTap__Field__c == 'evtName') {
                continue;
            }

            if (String.isBlank(mapping.CleverTap__Salesforce_Field__c) || 
                !record.getPopulatedFieldsAsMap().containsKey(mapping.CleverTap__Salesforce_Field__c)) {
                continue;
            }

            Object fieldValue = record.get(mapping.CleverTap__Salesforce_Field__c);
            if (fieldValue != null) {
                Object convertedValue = valueExtractor.convertFieldValue(
                    fieldValue, mapping.CleverTap__Data_Type__c
                );
                profileData.put(mapping.CleverTap__Field__c, convertedValue);
            }
        }
        
        return profileData;
    }

    private Map<String, Object> createFinalPayload(String identityValue, Map<String, Object> profileData, String entityType) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('identity', identityValue);
        
        Boolean isEvent = (entityType == 'event');
        if (isEvent) {
            payload.put('type', 'event');
            
            String eventName = getEventName();
            
            payload.put('evtName', eventName);
            payload.put('evtData', profileData);
        } else {
            payload.put('type', 'profile');
            payload.put('profileData', profileData);
        }
        
        payload.put('$source', 'SFDC');
        return payload;
    }

    private String getEventName() {
        CleverTap__Mapping__c eventNameMapping = specialMappings.get('evtName');
        
        if (eventNameMapping != null && String.isNotBlank(eventNameMapping.CleverTap__Salesforce_Field__c)) {
            return eventNameMapping.CleverTap__Salesforce_Field__c;
        } else {
            return 'sf_' + objectName.toLowerCase();
        }
    }

    private Map<String, String> getCredentials(String connectionId) {
        try {
            if (String.isBlank(connectionId)) {
                return null;
            }
            
            List<CleverTap__Config__c> configs = [
                SELECT Name, CleverTap__API_URL__c, CleverTap__Account_ID__c, 
                       CleverTap__Passcode__c, CleverTap__Region__c
                FROM CleverTap__Config__c
                WHERE Id = :connectionId OR Name = :connectionId
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                return null;
            }
            
            CleverTap__Config__c config = configs[0];
            
            return new Map<String, String>{
                'NAME' => config.Name,
                'DEV_NAME' => config.Name,
                'API_URL' => config.CleverTap__API_URL__c,
                'ACCOUNT_ID' => config.CleverTap__Account_ID__c,
                'PASSCODE' => config.CleverTap__Passcode__c,
                'REGION' => config.CleverTap__Region__c
            };
            
        } catch (Exception e) {
            return null;
        }
    }

    private String getRequestBody(Map<String, Object> payload) {
        Map<String, Object> requestPayload = new Map<String, Object>{
            'd' => new List<Map<String, Object>>{payload}
        };
        
        return JSON.serialize(requestPayload);
    }

    private HttpResponse sendToCleverTap(Map<String, String> credentials, Map<String, Object> payload, String entityType) {
        try {
            String apiUrl = buildApiUrl(credentials.get('API_URL'), entityType);
            if (String.isBlank(apiUrl)) {
                return null;
            }

            String jsonBody = getRequestBody(payload);
            HttpRequest req = createHttpRequest(apiUrl, credentials, jsonBody);

            Http http = new Http();
            return http.send(req);
            
        } catch (Exception e) {
            return null;
        }
    }

    private String buildApiUrl(String baseUrl, String entityType) {
        if (String.isBlank(baseUrl)) {
            return null;
        }

        Integer pathStart = baseUrl.indexOf('/1/');
        if (pathStart > 0) {
            baseUrl = baseUrl.substring(0, pathStart);
        }

        String apiPath = (entityType.toLowerCase() == 'event') ? eventApiPath : profileApiPath;
        return baseUrl + apiPath;
    }

    private HttpRequest createHttpRequest(String apiUrl, Map<String, String> credentials, String jsonBody) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(apiUrl);
        req.setMethod('POST');
        req.setTimeout(120000); 

        req.setHeader('X-CleverTap-Account-Id', credentials.get('ACCOUNT_ID'));
        req.setHeader('X-CleverTap-Passcode', credentials.get('PASSCODE'));
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        
        return req;
    }
    
    /**
     * @description Finish method to handle completion of the batch process
     * @param bc The batch context
     */
    public void finish(Database.BatchableContext bc) {
        createDetailedLogs();
    }

    private String buildSummaryLogMessage() {
        return 'Historical sync completed.\n' +
               'Records processed: ' + recordsProcessed + '\n' +
               'Records succeeded: ' + recordsSuccess + '\n' +
               'Records failed: ' + recordsFailed + '\n' +
               'Sync Configuration ID: ' + syncConfigId;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void createDetailedLogs() {
        if (eventLogs.isEmpty()) {
            return;
        }
        
        try {
            if (!Schema.SObjectType.CleverTap__Event__c.isCreateable()) {
                System.debug(LoggingLevel.ERROR, 'User does not have permission to create CleverTap__Event__c records');
                return;
            }
    
            if (!Schema.SObjectType.CleverTap__Event__c.fields.CleverTap__Status__c.isCreateable()) {
                System.debug(LoggingLevel.ERROR, 'User does not have permission to create some required fields');
                return;
            }
            
            List<CleverTap__Event__c> detailedLogs = new List<CleverTap__Event__c>();
            
            for (SerializableEventData eventData : eventLogs) {
                Boolean isSuccess = determineSuccess(eventData);

                CleverTap__Event__c eventLog = createDetailedLogEntry(eventData, isSuccess);
                detailedLogs.add(eventLog);
            }
            
            if (!detailedLogs.isEmpty()) {
                insert detailedLogs;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error creating detailed logs: ' + e.getMessage());
        }
    }

    private Boolean determineSuccess(SerializableEventData eventData) {
        if (eventData.statusCode != 200) {
            return false;
        }
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(eventData.responseBody);
            if (responseMap.containsKey('status')) {
                return 'success'.equalsIgnoreCase((String)responseMap.get('status'));
            }
        } catch (Exception e) {
            return true;
        }
        
        return true;
    }

    private CleverTap__Event__c createDetailedLogEntry(SerializableEventData eventData, Boolean isSuccess) {
        CleverTap__Event__c eventLog = new CleverTap__Event__c(
            CleverTap__Status__c = isSuccess ? 'Success' : 'Failed',
            CleverTap__Response__c = buildDetailedLogMessage(eventData)
        );

        setEventRecordReference(eventLog, eventData);
        
        return eventLog;
    }

    private String buildDetailedLogMessage(SerializableEventData eventData) {
        return String.isNotBlank(eventData.responseBody) ? 
            eventData.responseBody + '\nRequest: ' + eventData.requestBody : 
            eventData.requestBody;
    }

    private void setEventRecordReference(CleverTap__Event__c eventLog, SerializableEventData eventData) {
        String fieldName = eventData.recordType + '__c';
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.CleverTap__Event__c.fields.getMap();
        
        if (fieldsMap.containsKey(fieldName.toLowerCase())) {
            eventLog.put(fieldName, eventData.recordId);
        } else {
            eventLog.CleverTap__Response__c = eventData.recordType + ' ID: ' + eventData.recordId + '\n' + eventLog.CleverTap__Response__c;
        }
    }
    
    /**
     * @description Helper class for storing event data - simplified to reduce parameter list
     */
    public class SerializableEventData {
        public Id recordId;
        public String recordType;
        public Integer statusCode;
        public String responseBody;
        public String requestBody;
    }
}