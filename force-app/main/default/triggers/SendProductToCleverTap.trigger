trigger SendProductToCleverTap on Product2 (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processProducts(Trigger.new);
}