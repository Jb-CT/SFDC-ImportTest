trigger SendEventToCleverTap on Event (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processEvents(Trigger.new);
}