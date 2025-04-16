/**
 * @class DataProcessorImpl
 * @description Implementation of DataProcessor for handling integration between Salesforce and CleverTap.
 */
public with sharing class DataProcessorImpl implements DataProcessor { 
    // API endpoints
    private static final String PROFILE_API_PATH = '/1/upload';
    private static final String EVENT_API_PATH = '/1/upload';
    
    // Instance variables for the helper classes
    private EntityTransformer entityTransformer;
    private Config configHelper;
    private ResultLogger resultLogger;

    public DataProcessorImpl(EntityTransformer entityTransformer,Config configHelper,ResultLogger resultLogger) {
        this.entityTransformer = entityTransformer;
        this.configHelper = configHelper;
        this.resultLogger = resultLogger;
    }

    public void sendToCleverTap(SObject record, String recordType) {
        if (record == null) {
            return;
        }
        
        try {
            // Check access and configurations
            if (!isConfigurationAccessible()) {
                return;
            }
            
            // Get all connection mappings for this record
            List<EntityTransformer.ConnectionMapping> connectionMappings = 
                entityTransformer.mapToMultipleConnections(record, recordType);
            
            if (connectionMappings.isEmpty()) {
                return;
            }
            
            // Collect log data for batch logging
            List<ResultLogger.EventData> eventDataList = new List<ResultLogger.EventData>();
            
            // Process each connection mapping
            for (EntityTransformer.ConnectionMapping mapping : connectionMappings) {
                // Get credentials for this connection
                Map<String, String> credentials = getCredentialsForConnection(mapping.connectionId);
                if (!areCredentialsValid(credentials)) {
                    continue;
                }
                
                // Get the target entity type and set API endpoint
                Boolean isEvent = (mapping.payload.get('type') == 'event');
                credentials = adjustApiEndpoint(credentials, isEvent ? 'event' : 'profile');
                
                // Send to CleverTap
                HttpResponse response = sendRequest(credentials, mapping.payload);
                
                // Collect event data for later logging
                String requestBody = getRequestBody(mapping.payload);
                eventDataList.add(new ResultLogger.EventData(
                    record.Id, recordType, response, requestBody
                ));
            }
            
            // Enqueue logging as separate job
            if (!eventDataList.isEmpty()) {
                System.enqueueJob(new ResultLoggerJob(eventDataList));
            }
            
        } catch (Exception e) {
            // Log error in separate job
            List<ResultLogger.EventData> errorData = new List<ResultLogger.EventData>{
                new ResultLogger.EventData(record.Id, recordType, null, 'Error: ' + e.getMessage())
            };
            System.enqueueJob(new ResultLoggerJob(errorData));
        }
    }
    
    /**
     * @description Gets the target entity type from the sync configuration
     * @param recordType The record type
     * @return The target entity type (profile or event)
     */
    private String getTargetEntityType(String recordType) {
        if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return 'profile'; // Default to profile if no access
        }
        
        List<CleverTap_Sync_Configuration__c> configs = [
            SELECT CleverTap_Entity__c 
            FROM CleverTap_Sync_Configuration__c 
            WHERE Salesforce_Entity__c = :recordType 
            AND Status__c = 'Active'
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            return 'profile'; // Default to profile if no configuration found
        }
        
        return configs[0].CleverTap_Entity__c;
    }

    private Map<String, String> adjustApiEndpoint(Map<String, String> credentials, String targetEntityType) {
        Map<String, String> adjustedCredentials = new Map<String, String>(credentials);
        
        // Base URL without path
        String baseUrl = credentials.get('API_URL');
        if (String.isBlank(baseUrl)) {
            return adjustedCredentials;
        }
        
        // Remove existing path if any
        Integer pathStart = baseUrl.indexOf('/1/');
        if (pathStart > 0) {
            baseUrl = baseUrl.substring(0, pathStart);
        }
        
        // Add appropriate path based on entity type
        String apiPath = (targetEntityType.toLowerCase() == 'event') ? EVENT_API_PATH : PROFILE_API_PATH;
        
        // Update the API URL
        adjustedCredentials.put('API_URL', baseUrl + apiPath);
        
        return adjustedCredentials;
    }

    public void sendLeadToCleverTap(Lead lead) {
        sendToCleverTap(lead, 'Lead');
    }

    public void sendContactToCleverTap(Contact contact) {
        sendToCleverTap(contact, 'Contact');
    }

    public void sendAccountToCleverTap(Account account) {
        sendToCleverTap(account, 'Account');
    }

    public void sendOpportunityToCleverTap(Opportunity opportunity) {
        sendToCleverTap(opportunity, 'Opportunity');
    }

    private Boolean isConfigurationAccessible() {
        return CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible();
    }

    private Boolean hasSyncConfiguration(String recordType) {
        // Validate CRUD permission before SOQL operation
        if (!CleverTap_Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return false;
        }
        
        List<CleverTap_Sync_Configuration__c> syncConfigs = [
            SELECT Id FROM CleverTap_Sync_Configuration__c 
            WHERE Salesforce_Entity__c = :recordType 
            AND Status__c = 'Active' 
            LIMIT 1
        ];
        return !syncConfigs.isEmpty();
    }

    private Boolean areCredentialsValid(Map<String, String> credentials) {
        return (credentials != null && !credentials.isEmpty());
    }

    private String getRequestBody(Map<String, Object> mappedRecord) {
        Map<String, Object> payload = new Map<String, Object>{
            'd' => new List<Map<String, Object>>{mappedRecord}
        };
        return JSON.serialize(payload);
    }

    private HttpResponse sendRequest(Map<String, String> credentials, Map<String, Object> mappedRecord) {
        String jsonBody = getRequestBody(mappedRecord);
        
        // Create and validate request
        ApiRequest request = new ApiRequest(credentials, jsonBody);
        if (request.hasMissingCredentials()) {
            return null;
        }
        
        // Prepare and send HTTP request
        HttpRequest req = prepareHttpRequest(request);
        Http http = new Http();
        return http.send(req);
    }

    private HttpRequest prepareHttpRequest(ApiRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(request.apiUrl);
        req.setMethod('POST');
        req.setTimeout(120000); // Set timeout to 120 seconds
        
        // Set headers
        for (String headerKey : request.headers.keySet()) {
            req.setHeader(headerKey, request.headers.get(headerKey));
        }
        req.setBody(request.jsonBody);
        
        return req;
    }

    private Map<String, String> getCredentialsForConnection(String connectionId) {
        // Query the specific connection by ID or developer name
        if (String.isBlank(connectionId)) {
            return configHelper.getCredentials(); // Fallback to default method
        }
        
        // Check CRUD permissions
        if (!CleverTap_Config__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return null;
        }
        
        // Query the connection by ID
        List<CleverTap_Config__c> configs = [
            SELECT Name, CleverTap_API_URL__c, CleverTap_Account_ID__c, 
                CleverTap_Passcode__c, Region__c
            FROM CleverTap_Config__c
            WHERE Id = :connectionId OR Name = :connectionId
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            return null;
        }
        
        CleverTap_Config__c config = configs[0];
        
        // Build credentials map
        Map<String, String> credentials = new Map<String, String>{
            'NAME' => config.Name,
            'DEV_NAME' => config.Name,
            'API_URL' => config.CleverTap_API_URL__c,
            'ACCOUNT_ID' => config.CleverTap_Account_ID__c,
            'PASSCODE' => config.CleverTap_Passcode__c,
            'REGION' => config.Region__c
        };
        
        return credentials;
    }
}
