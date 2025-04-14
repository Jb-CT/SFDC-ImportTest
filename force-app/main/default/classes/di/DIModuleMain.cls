/**
 * @class DIModuleMain
 * @description Production implementation of DIModule
 */
public class DIModuleMain implements DIModule {
    // Singleton instance
    private static DataProcessor serviceInstance;
    
    /**
     * @description Provides the CleverTap service implementation
     * @return DataProcessor A singleton instance of the CleverTap service
     */
    public DataProcessor provideCleverTapService() {
        if (serviceInstance == null) {
            serviceInstance = new DataProcessorImpl();
        }
        return serviceInstance;
    }
}