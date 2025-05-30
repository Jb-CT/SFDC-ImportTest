trigger SendCampaignToCleverTap on Campaign (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processCampaigns(Trigger.new);
}