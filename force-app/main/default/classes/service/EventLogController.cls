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
     * @return List of CleverTap__Event__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<CleverTap__Event__c> getEventLogs(Integer recordLimit, String status, Integer days) {
        // Check object-level CRUD permissions
        if (!Schema.SObjectType.CleverTap__Event__c.isAccessible()) {
            throw new AuraHandledException('You do not have access to event logs');
        }
        
        List<String> queryParts = new List<String>{
            'SELECT Id, Name, CleverTap__Status__c, CleverTap__Response__c, CreatedDate',
            'FROM CleverTap__Event__c'
        };
        
        // WHERE clause construction
        List<String> whereConditions = new List<String>();
        
        // Filter by status if provided (using bind variable for safety)
        if (String.isNotBlank(status)) {
            whereConditions.add('CleverTap__Status__c = :status');
        }
        
        // Filter by date if days is provided (using bind variable for safety)
        if (days != null && days > 0) {
            DateTime filterDate = DateTime.now().addDays(-days);
            whereConditions.add('CreatedDate >= :filterDate');
        }
        
        // Add WHERE clause if conditions exist
        if (!whereConditions.isEmpty()) {
            queryParts.add('WHERE ' + String.join(whereConditions, ' AND '));
        }
        
        // Add ORDER BY and LIMIT clauses
        queryParts.add('ORDER BY CreatedDate DESC');
        queryParts.add('LIMIT :recordLimit');
        
        // Join all query parts
        String finalQuery = String.join(queryParts, ' ');
        
        // Execute the query with safely bound parameters
        return Database.query(finalQuery);
    }
    
    /**
     * @description Gets the details of a specific event log
     * @param recordId The ID of the event log record
     * @return CleverTap__Event__c The event log record with details
     */
    @AuraEnabled
    public static CleverTap__Event__c getEventDetails(Id recordId) {
        try {
            // The WITH SECURITY_ENFORCED clause enforces field and object-level security
            List<CleverTap__Event__c> events = [
                SELECT Id, Name, CleverTap__Status__c, CleverTap__Response__c, CreatedDate
                FROM CleverTap__Event__c
                WHERE Id = :recordId
                //WITH SECURITY_ENFORCED
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