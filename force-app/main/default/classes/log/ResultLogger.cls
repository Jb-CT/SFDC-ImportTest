/**
 * @class ResultLogger
 * @description Helper class for logging CleverTap integration events and errors.
 */
public with sharing class ResultLogger {
    /**
     * @description Event data wrapper class
     */
    public class EventData {
        public Id recordId;
        public String recordType;
        public HttpResponse response;
        public String requestBody;
        
        /**
         * @description Constructor for event data
         * @param recordId The ID of the Salesforce record
         * @param recordType The type of record
         * @param response The HTTP response from CleverTap
         * @param requestBody The request sent to CleverTap
         */
        public EventData(Id recordId, String recordType, HttpResponse response, String requestBody) {
            this.recordId = recordId;
            this.recordType = recordType;
            this.response = response;
            this.requestBody = requestBody;
        }
    }
    
    /**
     * @description Logs a CleverTap integration event
     * @param eventData The event data to log
     */
    public void logEvent(EventData eventData) {
        try {
            // Check permissions
            if (!canCreateEventLog()) {
                return;
            }
            
            // Determine success status
            Boolean isSuccess = determineSuccessStatus(eventData);
            
            // Create and populate event log
            CleverTap_Event__c eventLog = createEventLog(eventData, isSuccess);

            // Check if we have create permission on CleverTap_Event__c
            if (!Schema.sObjectType.CleverTap_Event__c.isCreateable()) {
                return;
                }
            
            // Insert the log
            insert eventLog;
        } catch (Exception e) {
            logError(e);
        }
    }

    private Boolean canCreateEventLog() {
        return Schema.sObjectType.CleverTap_Event__c.isCreateable();
    }

    private Boolean determineSuccessStatus(EventData eventData) {
        if (eventData.response == null) {
            return false;
        }
        
        if (eventData.response.getStatusCode() != 200) {
            return false;
        }
        
        return isSuccessResponse(eventData.response.getBody());
    }

    private Boolean isSuccessResponse(String responseBody) {
        if (String.isBlank(responseBody)) {
            return false;
        }
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            if (responseMap.containsKey('status')) {
                return 'success'.equalsIgnoreCase((String)responseMap.get('status'));
            }
        } catch (Exception e) {
            // If can't parse JSON, default to HTTP status
            return true;
        }
        
        return false;
    }

    private CleverTap_Event__c createEventLog(EventData eventData, Boolean isSuccess) {
        CleverTap_Event__c eventLog = new CleverTap_Event__c();
        eventLog.Status__c = isSuccess ? 'Success' : 'Failed';
        
        String responseBody = (eventData.response != null) ? eventData.response.getBody() : '';
        eventLog.Response__c = formatResponseContent(responseBody, eventData.requestBody);
        
        setRecordReference(eventLog, eventData);
        
        return eventLog;
    }

    private String formatResponseContent(String responseBody, String requestBody) {
        if (String.isBlank(responseBody)) {
            return requestBody;
        }
        
        return responseBody + '\nRequest: ' + requestBody;
    }

    private void setRecordReference(CleverTap_Event__c eventLog, EventData eventData) {
        String fieldName = eventData.recordType + '__c';
        
        if (hasField(CleverTap_Event__c.SObjectType, fieldName)) {
            eventLog.put(fieldName, eventData.recordId);
        } else {
            // Fallback - store record ID in description
            eventLog.Response__c = eventData.recordType + ' ID: ' + eventData.recordId + '\n' + eventLog.Response__c;
        }
    }

    private Boolean hasField(Schema.SObjectType sObjType, String fieldName) {
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        return fieldMap.containsKey(fieldName);
    }

    private void logError(Exception e) {
        // These debug statements provide essential troubleshooting information
        // and are only visible when appropriate debug levels are enabled
        System.debug(LoggingLevel.ERROR, 'Error logging CleverTap event: ' + e.getMessage());
        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
    }
}