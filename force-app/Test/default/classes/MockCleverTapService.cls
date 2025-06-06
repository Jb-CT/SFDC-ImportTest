/**
 * @class MockCleverTapService
 * @description Mock implementation of DataProcessor for testing
 */
@IsTest
public class MockCleverTapService implements DataProcessor {
    public Integer leadCallCount = 0;
    public Integer contactCallCount = 0;
    public Integer accountCallCount = 0;
    public Integer opportunityCallCount = 0;
    public Integer caseCallCount = 0;
    public Integer campaignCallCount = 0;
    public Integer eventCallCount = 0;
    public Integer taskCallCount = 0;
    public Integer campaignMemberCallCount = 0;
    public Integer serviceAppointmentCallCount = 0;
    public Integer genericCallCount = 0;
    public Integer quoteCallCount = 0;
    public Integer contractCallCount = 0;
    public Integer orderCallCount = 0;
    public Integer productCallCount = 0;
    public Integer pricebookCallCount = 0;
    public Integer assetCallCount = 0;
    public Integer opportunityLineItemCallCount = 0;

    public List<SObject> processedRecords = new List<SObject>();
    
    /**
     * @description Mock implementation of sendToCleverTap
     * @param record The record being processed
     * @param recordType The type of record
     */
    public void sendToCleverTap(SObject record, String recordType) {
        genericCallCount++;
        processedRecords.add(record);

        if (recordType == 'Lead') {
            leadCallCount++;
        } else if (recordType == 'Contact') {
            contactCallCount++;
        } else if (recordType == 'Account') {
            accountCallCount++;
        } else if (recordType == 'Opportunity') {
            opportunityCallCount++;
        } else if (recordType == 'Quote') {
            quoteCallCount++;
        } else if (recordType == 'Contract') {
            contractCallCount++;
        } else if (recordType == 'Order') {
            orderCallCount++;
        } else if (recordType == 'Product2') {
            productCallCount++;
        } else if (recordType == 'Pricebook2') {
            pricebookCallCount++;
        } else if (recordType == 'Asset') {
            assetCallCount++;
        } else if (recordType == 'OpportunityLineItem') {
            opportunityLineItemCallCount++;
        }
    }

    public void sendLeadToCleverTap(Lead lead) {
        leadCallCount++;
        processedRecords.add(lead);
    }

    public void sendContactToCleverTap(Contact contact) {
        contactCallCount++;
        processedRecords.add(contact);
    }

    public void sendAccountToCleverTap(Account account) {
        accountCallCount++;
        processedRecords.add(account);
    }

    public void sendOpportunityToCleverTap(Opportunity opportunity) {
        opportunityCallCount++;
        processedRecords.add(opportunity);
    }

    public void sendCaseToCleverTap(Case caseRecord) {
        caseCallCount++;
        processedRecords.add(caseRecord);
    }

    public void sendCampaignToCleverTap(Campaign campaign) {
        campaignCallCount++;
        processedRecords.add(campaign);
    }

    public void sendEventToCleverTap(Event event) {
        eventCallCount++;
        processedRecords.add(event);
    }

    public void sendTaskToCleverTap(Task task) {
        taskCallCount++;
        processedRecords.add(task);
    }

    public void sendCampaignMemberToCleverTap(CampaignMember campaignMember) {
        campaignMemberCallCount++;
        processedRecords.add(campaignMember);
    }

    public void sendServiceAppointmentToCleverTap(ServiceAppointment serviceAppointment) {
        serviceAppointmentCallCount++;
        processedRecords.add(serviceAppointment);
    }

    public void sendQuoteToCleverTap(Quote quote) {
        quoteCallCount++;
        processedRecords.add(quote);
    }

    public void sendContractToCleverTap(Contract contract) {
        contractCallCount++;
        processedRecords.add(contract);
    }

    public void sendOrderToCleverTap(Order orderRecord) {
        orderCallCount++;
        processedRecords.add(orderRecord);
    }

    public void sendProductToCleverTap(Product2 product) {
        productCallCount++;
        processedRecords.add(product);
    }

    public void sendPricebookToCleverTap(Pricebook2 pricebook) {
        pricebookCallCount++;
        processedRecords.add(pricebook);
    }

    public void sendAssetToCleverTap(Asset asset) {
        assetCallCount++;
        processedRecords.add(asset);
    }

    public void sendOpportunityLineItemToCleverTap(OpportunityLineItem lineItem) {
        opportunityLineItemCallCount++;
        processedRecords.add(lineItem);
    }

    public void resetCounters() {
        leadCallCount = 0;
        contactCallCount = 0;
        accountCallCount = 0;
        opportunityCallCount = 0;
        genericCallCount = 0;
        processedRecords.clear();
    }
}