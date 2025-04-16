trigger SendContactToCleverTap on Contact (after insert, after update) {
    new IntegrationHandler(new DIModuleMain()).processContacts(Trigger.new);
}