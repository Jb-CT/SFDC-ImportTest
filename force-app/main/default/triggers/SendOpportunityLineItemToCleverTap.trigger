trigger SendOpportunityLineItemToCleverTap on OpportunityLineItem (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processOpportunityLineItems(Trigger.new);
}