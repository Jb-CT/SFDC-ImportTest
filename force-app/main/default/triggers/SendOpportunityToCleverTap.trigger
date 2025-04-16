trigger SendOpportunityToCleverTap on Opportunity (after insert, after update) {
    new IntegrationHandler(new DIModuleMain()).processOpportunities(Trigger.new);
}