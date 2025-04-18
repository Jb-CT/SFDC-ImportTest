/**
 * @class DIModuleMain
 * @description Production implementation of DIModule
 */
public class DIModuleMain implements DIModule {
    private static DataProcessor dataProcessor;
    private static EntityTransformer entityTransformer;
    private static Config config;
    private static ResultLogger resultLogger;

    public IntegrationHandler provideIntegrationHandler() {
        return new IntegrationHandler(this);
    }

    public DataProcessor provideCleverTapService() {
        if (dataProcessor == null) {
            dataProcessor = new DataProcessorImpl(
                provideEntityTransformer(), 
                provideConfig(), 
                provideResultLogger()
            );
        }
        
        return dataProcessor;
    }

    public EntityTransformer provideEntityTransformer() {
        if (entityTransformer == null) {
            entityTransformer = new EntityTransformer();
        }

        return entityTransformer;
    }

    public Config provideConfig() {
        if (config == null) {
            config = new Config();
        }

        return config;
    }

    public ResultLogger provideResultLogger() {
        if (resultLogger == null) {
            resultLogger = new ResultLogger();
        }

        return resultLogger;
    }
}