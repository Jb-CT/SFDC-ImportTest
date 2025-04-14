trigger SendAccountToCleverTap on Account (after insert, after update) {
    IntegrationHandler.getInstance().processAccounts(Trigger.new);
}
