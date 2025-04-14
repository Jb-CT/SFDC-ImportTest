trigger SendContactToCleverTap on Contact (after insert, after update) {
    IntegrationHandler.getInstance().processContacts(Trigger.new);
}