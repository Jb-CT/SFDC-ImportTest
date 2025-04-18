/**
 * @interface DIModule
 * @description Interface for dependency injection module
 */
public interface DIModule {
    IntegrationHandler provideIntegrationHandler();
    DataProcessor provideCleverTapService();
    EntityTransformer provideEntityTransformer();
    Config provideConfig();
    ResultLogger provideResultLogger();
}