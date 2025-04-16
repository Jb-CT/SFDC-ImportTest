/**
 * @class ResultLoggerJob
 * @description Queueable job for asynchronously logging CleverTap integration events.
 * Uses a serializable wrapper to handle HttpResponse data that cannot be serialized directly.
 */
public class ResultLoggerJob implements Queueable {
    private static final String STATUS_FIELD = 'Status__c';
    private static final String RESPONSE_FIELD = 'Response__c';
    
    private List<EventDataWrapper> eventDataList;
    
    /**
     * @class EventDataWrapper
     * @description Serializable wrapper class for event data.
     * Extracts and stores only the serializable portions of HttpResponse.
     */
    public class EventDataWrapper {
        public Id recordId;
        public String recordType;
        public Integer statusCode;
        public String responseBody;
        public String requestBody;
        
        /**
         * @description Constructor that extracts serializable data from HttpResponse
         * @param recordId The ID of the record related to this event
         * @param recordType The type of record (Lead, Contact, etc.)
         * @param response The HTTP response (will be extracted, not stored directly)
         * @param requestBody The request body that was sent
         */
        public EventDataWrapper(Id recordId, String recordType, HttpResponse response, String requestBody) {
            this.recordId = recordId;
            this.recordType = recordType;
            this.requestBody = requestBody;
            
            // Extract only what we need from HttpResponse
            if (response != null) {
                this.statusCode = response.getStatusCode();
                this.responseBody = response.getBody();
            }
        }
    }

    public ResultLoggerJob(List<ResultLogger.EventData> originalEventDataList) {
        this.eventDataList = new List<EventDataWrapper>();
        
        // Convert non-serializable EventData to serializable EventDataWrapper
        for (ResultLogger.EventData data : originalEventDataList) {
            HttpResponse response = data.response;
            EventDataWrapper wrapper = new EventDataWrapper(
                data.recordId,
                data.recordType,
                response,  // Will be extracted, not stored directly
                data.requestBody
            );
            this.eventDataList.add(wrapper);
        }
    }
    
    /**
     * @description Executes the queueable job to create event log records
     * @param context The queueable context
     */
    public void execute(QueueableContext context) {
        try {
            List<CleverTap_Event__c> logsToInsert = createLogRecords();
            
            if (!logsToInsert.isEmpty()) {
                insertLogs(logsToInsert);
            }
        } catch (Exception e) {
            logError(e);
        }
    }

    private List<CleverTap_Event__c> createLogRecords() {
        List<CleverTap_Event__c> logsToInsert = new List<CleverTap_Event__c>();
        
        for (EventDataWrapper eventData : eventDataList) {
            // Create and add the log record
            CleverTap_Event__c eventLog = createSingleLogRecord(eventData);
            logsToInsert.add(eventLog);
        }
        
        return logsToInsert;
    }

    private CleverTap_Event__c createSingleLogRecord(EventDataWrapper eventData) {
        // Determine success status
        Boolean isSuccess = determineSuccessStatus(eventData);
        
        // Create event log record
        CleverTap_Event__c eventLog = new CleverTap_Event__c(
            Status__c = isSuccess ? 'Success' : 'Failed',
            Response__c = formatResponseContent(eventData)
        );
        
        // Set the record reference
        setRecordReference(eventLog, eventData);
        
        return eventLog;
    }

    private Boolean determineSuccessStatus(EventDataWrapper eventData) {
        if (eventData.statusCode != 200) {
            return false;
        }
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(eventData.responseBody);
            if (responseMap.containsKey('status')) {
                return 'success'.equalsIgnoreCase((String)responseMap.get('status'));
            }
        } catch (Exception e) {
            return true; // Default to HTTP status
        }
        
        return true;
    }

    private String formatResponseContent(EventDataWrapper eventData) {
        if (String.isNotBlank(eventData.responseBody)) {
            return eventData.responseBody + '\nRequest: ' + eventData.requestBody;
        }
        return eventData.requestBody;
    }

    private void setRecordReference(CleverTap_Event__c eventLog, EventDataWrapper eventData) {
        String fieldName = eventData.recordType + '__c';
        
        // Check if field exists before setting it
        if (Schema.SObjectType.CleverTap_Event__c.fields.getMap().containsKey(fieldName.toLowerCase())) {
            eventLog.put(fieldName, eventData.recordId);
        } else {
            // Fallback - store record ID in description
            eventLog.Response__c = eventData.recordType + ' ID: ' + eventData.recordId + '\n' + eventLog.Response__c;
        }
    }

    private void insertLogs(List<CleverTap_Event__c> logsToInsert) {
        // Verify field-level security and insert
        if (Schema.SObjectType.CleverTap_Event__c.isCreateable()) {
            insert logsToInsert;
            // Log success with appropriate logging level
            logSuccess(logsToInsert.size());
        }
    }

    private void logSuccess(Integer count) {
        // Only log at INFO level for monitoring purposes
        System.debug(LoggingLevel.INFO, 'Successfully inserted ' + count + ' CleverTap event logs');
    }

    private void logError(Exception e) {
        // These are critical errors that must be preserved for troubleshooting integration issues
        System.debug(LoggingLevel.ERROR, 'Error in ResultLoggerJob: ' + e.getMessage());
        System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
    }
}