/**
 * @interface DataProcessor
 * @description Interface for CleverTap integration service
 */
public interface DataProcessor {
    /**
     * @description Sends a Salesforce record to CleverTap.
     * @param record The Salesforce record to be sent.
     * @param recordType The type of record being sent ('Lead', 'Contact', 'Account', 'Opportunity').
     */
    void sendToCleverTap(SObject record, String recordType);
    void sendLeadToCleverTap(Lead lead);
    void sendContactToCleverTap(Contact contact);
    void sendAccountToCleverTap(Account account);
    void sendOpportunityToCleverTap(Opportunity opportunity);
    void sendCaseToCleverTap(Case caseRecord);
    void sendCampaignToCleverTap(Campaign campaign);
    void sendEventToCleverTap(Event event);
    void sendTaskToCleverTap(Task task);
    void sendCampaignMemberToCleverTap(CampaignMember campaignMember);
    void sendServiceAppointmentToCleverTap(ServiceAppointment serviceAppointment);
}