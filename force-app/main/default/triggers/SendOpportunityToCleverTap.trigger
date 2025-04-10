trigger SendOpportunityToCleverTap on Opportunity (after insert, after update) {
    IntegrationHandler.processRecords(Trigger.new);
}