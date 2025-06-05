trigger SendQuoteToCleverTap on Quote (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processQuotes(Trigger.new);
}