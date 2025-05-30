trigger SendTaskToCleverTap on Task (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processTasks(Trigger.new);
}