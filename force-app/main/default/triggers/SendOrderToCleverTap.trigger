trigger SendOrderToCleverTap on Order (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processOrders(Trigger.new);
}