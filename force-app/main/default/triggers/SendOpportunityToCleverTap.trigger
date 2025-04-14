trigger SendOpportunityToCleverTap on Opportunity (after insert, after update) {
    IntegrationHandler.getInstance().processOpportunities(Trigger.new);
}