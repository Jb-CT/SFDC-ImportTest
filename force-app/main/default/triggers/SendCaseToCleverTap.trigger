trigger SendCaseToCleverTap on Case (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processCases(Trigger.new);
}