/**
 * @class DIModuleMain
 * @description Production implementation of DIModule
 */
public class DIModuleMain implements DIModule {
    private static DataProcessor dataProcessor;

    public DataProcessor provideCleverTapService() {
        if (dataProcessor == null) {

            EntityTransformer entityTransformer = provideEntityTransformer();
            Config config = provideConfig();
            ResultLogger resultLogger = provideResultLogger();

            dataProcessor = new DataProcessorImpl(entityTransformer, config, resultLogger);
        }
        return dataProcessor;
    }

    private EntityTransformer provideEntityTransformer(){
        return new EntityTransformer();
    }

    private Config provideConfig(){
        return new Config();
    }

    private ResultLogger provideResultLogger(){
        return new ResultLogger();
    }
}