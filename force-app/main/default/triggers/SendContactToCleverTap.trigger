trigger SendContactToCleverTap on Contact (after insert, after update) {
    IntegrationHandler.processContacts(Trigger.new);
}