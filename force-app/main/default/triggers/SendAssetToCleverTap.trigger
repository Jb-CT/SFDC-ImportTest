trigger SendAssetToCleverTap on Asset (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processAssets(Trigger.new);
}