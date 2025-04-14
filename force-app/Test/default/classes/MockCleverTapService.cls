/**
 * @class MockCleverTapService
 * @description Mock implementation of DataProcessor for testing
 */
@IsTest
public class MockCleverTapService implements DataProcessor {
    // Counters to track method calls
    public Integer leadCallCount = 0;
    public Integer contactCallCount = 0;
    public Integer accountCallCount = 0;
    public Integer opportunityCallCount = 0;
    public Integer genericCallCount = 0;
    
    // Records processed for verification
    public List<SObject> processedRecords = new List<SObject>();
    
    /**
     * @description Mock implementation of sendToCleverTap
     * @param record The record being processed
     * @param recordType The type of record
     */
    public void sendToCleverTap(SObject record, String recordType) {
        genericCallCount++;
        processedRecords.add(record);
        
        // Update the appropriate counter based on record type
        if (recordType == 'Lead') {
            leadCallCount++;
        } else if (recordType == 'Contact') {
            contactCallCount++;
        } else if (recordType == 'Account') {
            accountCallCount++;
        } else if (recordType == 'Opportunity') {
            opportunityCallCount++;
        }
    }
    
    /**
     * @description Mock implementation of sendLeadToCleverTap
     * @param lead The Lead record
     */
    public void sendLeadToCleverTap(Lead lead) {
        leadCallCount++;
        processedRecords.add(lead);
    }
    
    /**
     * @description Mock implementation of sendContactToCleverTap
     * @param contact The Contact record
     */
    public void sendContactToCleverTap(Contact contact) {
        contactCallCount++;
        processedRecords.add(contact);
    }
    
    /**
     * @description Mock implementation of sendAccountToCleverTap
     * @param account The Account record
     */
    public void sendAccountToCleverTap(Account account) {
        accountCallCount++;
        processedRecords.add(account);
    }
    
    /**
     * @description Mock implementation of sendOpportunityToCleverTap
     * @param opportunity The Opportunity record
     */
    public void sendOpportunityToCleverTap(Opportunity opportunity) {
        opportunityCallCount++;
        processedRecords.add(opportunity);
    }
    
    /**
     * @description Resets all counters
     */
    public void resetCounters() {
        leadCallCount = 0;
        contactCallCount = 0;
        accountCallCount = 0;
        opportunityCallCount = 0;
        genericCallCount = 0;
        processedRecords.clear();
    }
}