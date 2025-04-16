trigger SendAccountToCleverTap on Account (after insert, after update) {
    new IntegrationHandler(new DIModuleMain()).processAccounts(Trigger.new);
}
