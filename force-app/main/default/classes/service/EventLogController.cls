/**
 * @class EventLogController
 * @description Controller class for handling CleverTap event log operations.
 */
public with sharing class EventLogController {
    /**
     * @description Gets event logs with optional filtering
     * @param recordLimit The maximum number of records to return
     * @param status Filter by status (optional)
     * @param days Number of days to look back (optional)
     * @return List of CleverTap_Event__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<CleverTap_Event__c> getEventLogs(Integer recordLimit, String status, Integer days) {
        // Check object-level CRUD permissions
        if (!Schema.SObjectType.CleverTap_Event__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to event logs');
        }
        
        // Check field-level permissions 
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.CleverTap_Event__c.fields.getMap();
        if (!fieldMap.get('Name').getDescribe().isAccessible() ||
            !fieldMap.get('Status__c').getDescribe().isAccessible() ||
            !fieldMap.get('Response__c').getDescribe().isAccessible() ||
            !fieldMap.get('CreatedDate').getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have access to one or more required fields');
        }
        
        // Define query format strings using camelCase for local variables
        String baseQuery = 
            'SELECT Id, Name, Status__c, Response__c, CreatedDate FROM CleverTap_Event__c';
        String whereStatus = 
            ' WHERE Status__c = :status';
        String whereDate = 
            ' WHERE CreatedDate >= :filterDate';
        String andDate = 
            ' AND CreatedDate >= :filterDate';
        String orderLimit = 
            ' ORDER BY CreatedDate DESC LIMIT :recordLimit';
        
        // Build the query
        String query = baseQuery;
        
        // Calculate filter date if needed
        DateTime filterDate;
        if (days != null && days > 0) {
            filterDate = DateTime.now().addDays(-days);
        }
        
        // Add conditions
        if (String.isNotBlank(status)) {
            query += whereStatus;
            if (days != null && days > 0) {
                query += andDate;
            }
        } else if (days != null && days > 0) {
            query += whereDate;
        }
        
        // Add order by and limit
        query += orderLimit;
        
        // Execute the query with safely bound parameters
        return Database.query(query);
    }
    
    /**
     * @description Gets the details of a specific event log
     * @param recordId The ID of the event log record
     * @return CleverTap_Event__c The event log record with details
     */
    @AuraEnabled
    public static CleverTap_Event__c getEventDetails(Id recordId) {
        try {
            // The WITH SECURITY_ENFORCED clause enforces field and object-level security
            List<CleverTap_Event__c> events = [
                SELECT Id, Name, Status__c, Response__c, CreatedDate
                FROM CleverTap_Event__c
                WHERE Id = :recordId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (events.isEmpty()) {
                throw new AuraHandledException('Event log not found');
            }
            
            return events[0];
        } catch (System.QueryException e) {
            // This exception is thrown when security enforcement fails
            throw new AuraHandledException('Insufficient access permissions: ' + e.getMessage());
        }
    }
}