/**
 * @class DataProcessorImpl
 * @description Implementation of DataProcessor for handling integration between Salesforce and CleverTap.
 */
public with sharing class DataProcessorImpl implements DataProcessor { 
    private static final String PROFILE_API_PATH = '/1/upload';
    private static final String EVENT_API_PATH = '/1/upload';

    private final EntityTransformer entityTransformer;
    private final Config configHelper;
    private final ResultLogger resultLogger;

    public DataProcessorImpl(EntityTransformer entityTransformer,Config configHelper,ResultLogger resultLogger) {
        this.entityTransformer = entityTransformer;
        this.configHelper = configHelper;
        this.resultLogger = resultLogger;
    }

    private static Boolean isProcessing = false;

    public void sendToCleverTap(SObject record, String recordType) {
        if (record == null) {
            return;
        }
    
        if (isProcessing) {
            return;
        }
        
        try {
            isProcessing = true;
    
            if (!isConfigurationAccessible()) {
                return;
            }
            
            List<EntityTransformer.ConnectionMapping> connectionMappings = 
                entityTransformer.mapToMultipleConnections(record, recordType);
            
            if (connectionMappings.isEmpty()) {
                return;
            }
            
            List<ResultLogger.EventData> eventDataList = new List<ResultLogger.EventData>();
            
            for (EntityTransformer.ConnectionMapping mapping : connectionMappings) {
                Map<String, String> credentials = getCredentialsForConnection(mapping.connectionId);
                if (!areCredentialsValid(credentials)) {
                    continue;
                }
                
                Boolean isEvent = (mapping.payload.get('type') == 'event');
                credentials = adjustApiEndpoint(credentials, isEvent ? 'event' : 'profile');
                
                HttpResponse response = sendRequest(credentials, mapping.payload);
                
                String requestBody = getRequestBody(mapping.payload);
                eventDataList.add(new ResultLogger.EventData(
                    record.Id, recordType, response, requestBody
                ));
            }
            
            if (!eventDataList.isEmpty()) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new ResultLoggerJob(eventDataList));
                }
            }
        } catch (Exception e) {
            List<ResultLogger.EventData> errorData = new List<ResultLogger.EventData>{
                new ResultLogger.EventData(record.Id, recordType, null, 'Error: ' + e.getMessage())
            };
            
            if (!Test.isRunningTest()) {
                System.enqueueJob(new ResultLoggerJob(errorData));
            }
        } finally {
            isProcessing = false;
        }
    }
    
    /**
     * @description Gets the target entity type from the sync configuration
     * @param recordType The record type
     * @return The target entity type (profile or event)
     */
    private String getTargetEntityType(String recordType) {
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return 'profile'; 
        }
        
        List<CleverTap__Sync_Configuration__c> configs = [
            SELECT CleverTap__Entity__c 
            FROM CleverTap__Sync_Configuration__c 
            WHERE CleverTap__Salesforce_Entity__c = :recordType 
            AND CleverTap__Status__c = 'Active'
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            return 'profile'; 
        }
        
        return configs[0].CleverTap__Entity__c;
    }

    private Map<String, String> adjustApiEndpoint(Map<String, String> credentials, String targetEntityType) {
        Map<String, String> adjustedCredentials = new Map<String, String>(credentials);

        String baseUrl = credentials.get('API_URL');
        if (String.isBlank(baseUrl)) {
            return adjustedCredentials;
        }

        Integer pathStart = baseUrl.indexOf('/1/');
        if (pathStart > 0) {
            baseUrl = baseUrl.substring(0, pathStart);
        }

        String apiPath = (targetEntityType.toLowerCase() == 'event') ? EVENT_API_PATH : PROFILE_API_PATH;
        
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

    public void sendCaseToCleverTap(Case caseRecord) {
        sendToCleverTap(caseRecord, 'Case');
    }

    public void sendCampaignToCleverTap(Campaign campaign) {
        sendToCleverTap(campaign, 'Campaign');
    }

    public void sendEventToCleverTap(Event event) {
        sendToCleverTap(event, 'Event');
    }

    public void sendTaskToCleverTap(Task task) {
        sendToCleverTap(task, 'Task');
    }

    public void sendCampaignMemberToCleverTap(CampaignMember campaignMember) {
        sendToCleverTap(campaignMember, 'CampaignMember');
    }

    public void sendServiceAppointmentToCleverTap(ServiceAppointment serviceAppointment) {
        sendToCleverTap(serviceAppointment, 'ServiceAppointment');
    }

    public void sendQuoteToCleverTap(Quote quote) {
        sendToCleverTap(quote, 'Quote');
    }

    public void sendContractToCleverTap(Contract contract) {
        sendToCleverTap(contract, 'Contract');
    }

    public void sendOrderToCleverTap(Order orderRecord) {
        sendToCleverTap(orderRecord, 'Order');
    }

    public void sendProductToCleverTap(Product2 product) {
        sendToCleverTap(product, 'Product2');
    }

    public void sendPricebookToCleverTap(Pricebook2 pricebook) {
        sendToCleverTap(pricebook, 'Pricebook2');
    }

    public void sendAssetToCleverTap(Asset asset) {
        sendToCleverTap(asset, 'Asset');
    }

    public void sendOpportunityLineItemToCleverTap(OpportunityLineItem lineItem) {
        sendToCleverTap(lineItem, 'OpportunityLineItem');
    }

    private Boolean isConfigurationAccessible() {
        return CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible();
    }

    private Boolean hasSyncConfiguration(String recordType) {
        if (!CleverTap__Sync_Configuration__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return false;
        }
        
        List<CleverTap__Sync_Configuration__c> syncConfigs = [
            SELECT Id FROM CleverTap__Sync_Configuration__c 
            WHERE CleverTap__Salesforce_Entity__c = :recordType 
            AND CleverTap__Status__c = 'Active' 
            WITH SECURITY_ENFORCED
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

        ApiRequest request = new ApiRequest(credentials, jsonBody);
        if (request.hasMissingCredentials()) {
            return null;
        }
        
        HttpRequest req = prepareHttpRequest(request);
        Http http = new Http();
        return http.send(req);
    }

    private HttpRequest prepareHttpRequest(ApiRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(request.apiUrl);
        req.setMethod('POST');
        req.setTimeout(120000); 

        for (String headerKey : request.headers.keySet()) {
            req.setHeader(headerKey, request.headers.get(headerKey));
        }
        req.setBody(request.jsonBody);
        
        return req;
    }

    private Map<String, String> getCredentialsForConnection(String connectionId) {
        if (String.isBlank(connectionId)) {
            return configHelper.getCredentials(); 
        }

        if (!CleverTap__Config__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()) {
            return null;
        }

        List<CleverTap__Config__c> configs = [
            SELECT Name, CleverTap__API_URL__c, CleverTap__Account_ID__c, 
                CleverTap__Region__c
            FROM CleverTap__Config__c
            WHERE Id = :connectionId OR Name = :connectionId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            return null;
        }
        
        CleverTap__Config__c config = configs[0];

        Map<String, String> credentials = new Map<String, String>{
            'NAME' => config.Name,
            'DEV_NAME' => config.Name,
            'API_URL' => config.CleverTap__API_URL__c,
            'ACCOUNT_ID' => config.CleverTap__Account_ID__c,
            'PASSCODE' => PasscodeHelper.getPasscode(config.Id),
            'REGION' => config.CleverTap__Region__c
        };
        
        return credentials;
    }
}