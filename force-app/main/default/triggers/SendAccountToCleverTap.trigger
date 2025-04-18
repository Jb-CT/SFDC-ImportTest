trigger SendAccountToCleverTap on Account (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processAccounts(Trigger.new);
}
