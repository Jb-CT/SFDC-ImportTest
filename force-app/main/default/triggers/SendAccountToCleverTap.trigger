trigger SendAccountToCleverTap on Account (after insert, after update) {
    IntegrationHandler.processAccounts(Trigger.new);
}
