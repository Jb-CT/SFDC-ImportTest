trigger SendContactToCleverTap on Contact (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processContacts(Trigger.new);
}