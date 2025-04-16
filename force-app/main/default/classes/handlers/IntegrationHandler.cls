/**
 * @class IntegrationHandler
 * @description Handles integration operations between Salesforce and CleverTap by delegating record processing to appropriate services.
 */
public with sharing class IntegrationHandler {
    private static DIModule diModule = new DIModuleMain();
    
    private static IntegrationHandler instance;
    
    public static IntegrationHandler getInstance() {
        if (instance == null) {
            instance = new IntegrationHandler();
        }
        return instance;
    }
    
    /**
     * @description Sets the dependency injection module (primarily for testing)
     * @param module The DIModule to use
     */
    @TestVisible
    public static void setDIModule(DIModule module) {
        diModule = module;
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