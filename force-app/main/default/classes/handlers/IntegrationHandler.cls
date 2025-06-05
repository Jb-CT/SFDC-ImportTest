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
    
    public void processCases(List<Case> cases) {
        processRecords(cases);
    }

    public void processCampaigns(List<Campaign> campaigns) {
        processRecords(campaigns);
    }

    public void processEvents(List<Event> events) {
        processRecords(events);
    }

    public void processTasks(List<Task> tasks) {
        processRecords(tasks);
    }

    public void processCampaignMembers(List<CampaignMember> campaignMembers) {
        processRecords(campaignMembers);
    }

    public void processServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        processRecords(serviceAppointments);
    }

    public void processQuotes(List<Quote> quotes) {
        processRecords(quotes);
    }

    public void processContracts(List<Contract> contracts) {
        processRecords(contracts);
    }

    public void processOrders(List<Order> orders) {
        processRecords(orders);
    }

    public void processProducts(List<Product2> products) {
        processRecords(products);
    }

    public void processPricebooks(List<Pricebook2> pricebooks) {
        processRecords(pricebooks);
    }

    public void processAssets(List<Asset> assets) {
        processRecords(assets);
    }

    public void processOpportunityLineItems(List<OpportunityLineItem> lineItems) {
        processRecords(lineItems);
    }
}
