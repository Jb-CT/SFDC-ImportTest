trigger SendOpportunityToCleverTap on Opportunity (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processOpportunities(Trigger.new);
}