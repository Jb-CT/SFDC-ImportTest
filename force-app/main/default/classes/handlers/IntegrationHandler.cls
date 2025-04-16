/**
 * @class IntegrationHandler
 * @description Handles integration operations between Salesforce and CleverTap by delegating record processing to appropriate services.
 */
public with sharing class IntegrationHandler {
    private final DIModule diModule;

    public IntegrationHandler(DIModule diModule){
        this.diModule = diModule;
    }

    public void processRecords(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return;
        }
        
        // Use the generic queueable class for all object types with DIModule
        System.enqueueJob(new EntityExportJob(records, diModule));
    }

    public void processLeads(List<Lead> leads) {
        processRecords(leads);
    }

    public void processContacts(List<Contact> contacts) {
        processRecords(contacts);
    }

    public void processAccounts(List<Account> accounts) {
        processRecords(accounts);
    }

    public void processOpportunities(List<Opportunity> opportunities) {
        processRecords(opportunities);
    }
}
