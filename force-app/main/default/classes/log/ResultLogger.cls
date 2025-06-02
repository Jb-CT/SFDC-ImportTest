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

            Boolean isSuccess = determineSuccessStatus(eventData);

            CleverTap__Event__c eventLog = createEventLog(eventData, isSuccess);

            if (!Schema.sObjectType.CleverTap__Event__c.isCreateable()) {
                return;
                }
            
            // Insert the log
            insert eventLog;
        } catch (Exception e) {
            //logError(e);
            return ;
        }
    }

    private Boolean canCreateEventLog() {
        return Schema.sObjectType.CleverTap__Event__c.isCreateable();
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

    private CleverTap__Event__c createEventLog(EventData eventData, Boolean isSuccess) {
        if (!Schema.sObjectType.CleverTap__Event__c.fields.CleverTap__Status__c.isCreateable() ||
        !Schema.sObjectType.CleverTap__Event__c.fields.CleverTap__Response__c.isCreateable()) {
        return null;
        }

        CleverTap__Event__c eventLog = new CleverTap__Event__c();
        eventLog.CleverTap__Status__c = isSuccess ? 'Success' : 'Failed';
        
        String responseBody = (eventData.response != null) ? eventData.response.getBody() : '';
        eventLog.CleverTap__Response__c = formatResponseContent(responseBody, eventData.requestBody);
        
        setRecordReference(eventLog, eventData);
        
        return eventLog;
    }

    private String formatResponseContent(String responseBody, String requestBody) {
        if (String.isBlank(responseBody)) {
            return requestBody;
        }
        
        return responseBody + '\nRequest: ' + requestBody;
    }

    private void setRecordReference(CleverTap__Event__c eventLog, EventData eventData) {
        if (eventData.recordType == 'Contact') {
            eventLog.CleverTap__Contact__c = eventData.recordId;
            return;
        } else if (eventData.recordType == 'Lead') {
            eventLog.CleverTap__Lead__c = eventData.recordId;
            return;
        } else if (eventData.recordType == 'Account') {
            eventLog.put('CleverTap__Account__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'Opportunity') {
            eventLog.put('CleverTap__Opportunity__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'Case') {
            eventLog.put('CleverTap__Case__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'Campaign') {
            eventLog.put('CleverTap__Campaign__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'Event') {
            eventLog.put('CleverTap__Activity_Event__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'Task') {
            eventLog.put('CleverTap__Activity_Task__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'CampaignMember') {
            eventLog.put('CleverTap__CampaignMember__c', eventData.recordId);
            return;
        } else if (eventData.recordType == 'ServiceAppointment') {
            eventLog.put('CleverTap__ServiceAppointment__c', eventData.recordId);
            return;
        }
        
        String fieldName = 'CleverTap__' + eventData.recordType + '__c';
        Map<String, Schema.SObjectField> fieldMap = CleverTap__Event__c.SObjectType.getDescribe().fields.getMap();
        
        if (fieldMap.containsKey(fieldName.toLowerCase())) {
            eventLog.put(fieldName, eventData.recordId);
        } else {
            eventLog.CleverTap__Response__c = eventData.recordType + ' ID: ' + eventData.recordId + '\n' + eventLog.CleverTap__Response__c;
        }
    }

    private Boolean hasField(Schema.SObjectType sObjType, String fieldName) {
        Map<String, Schema.SObjectField> fieldMap = sObjType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
        return fieldMap.containsKey(fieldName.toLowerCase());
    }


    public void logEventBatch(List<EventData> eventDataBatch) {
        if (!Schema.sObjectType.CleverTap__Event__c.isCreateable()) {
            System.debug(LoggingLevel.ERROR, 'Insufficient permissions to create CleverTap Event log records');
            return;
        }

        if (!Schema.sObjectType.CleverTap__Event__c.fields.CleverTap__Status__c.isCreateable() ||
            !Schema.sObjectType.CleverTap__Event__c.fields.CleverTap__Response__c.isCreateable()) {
            System.debug(LoggingLevel.ERROR, 'Insufficient permissions to create some required fields');
            return;
        }
        
        List<CleverTap__Event__c> eventLogs = new List<CleverTap__Event__c>();
        
        for (EventData eventData : eventDataBatch) {
            Boolean isSuccess = determineSuccessStatus(eventData);
            CleverTap__Event__c eventLog = createEventLog(eventData, isSuccess);
            if (eventLog != null) {
                eventLogs.add(eventLog);
            }
        }
        
        if (!eventLogs.isEmpty()) {
            insert eventLogs;
        }
    }
}