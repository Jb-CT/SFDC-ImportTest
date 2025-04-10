/**
 * @interface ICleverTapService
 * @description Interface for CleverTap integration service
 */
public interface ICleverTapService {
    
    /**
     * @description Sends a Salesforce record to CleverTap.
     * @param record The Salesforce record to be sent.
     * @param recordType The type of record being sent ('Lead', 'Contact', 'Account', 'Opportunity').
     */
    void sendToCleverTap(SObject record, String recordType);
    
    /**
     * @description Wrapper method for sending Lead records to CleverTap.
     * @param lead The Lead record to be sent to CleverTap.
     */
    void sendLeadToCleverTap(Lead lead);
    
    /**
     * @description Wrapper method for sending Contact records to CleverTap.
     * @param contact The Contact record to be sent to CleverTap.
     */
    void sendContactToCleverTap(Contact contact);
    
    /**
     * @description Wrapper method for sending Account records to CleverTap.
     * @param account The Account record to be sent to CleverTap.
     */
    void sendAccountToCleverTap(Account account);
    
    /**
     * @description Wrapper method for sending Opportunity records to CleverTap.
     * @param opportunity The Opportunity record to be sent to CleverTap.
     */
    void sendOpportunityToCleverTap(Opportunity opportunity);
}