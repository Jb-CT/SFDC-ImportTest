trigger SendPricebookToCleverTap on Pricebook2 (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processPricebooks(Trigger.new);
}