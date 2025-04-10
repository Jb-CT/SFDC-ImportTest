/**
 * @class ProductionModule
 * @description Production implementation of DIModule
 */
public class ProductionModule implements DIModule {
    
    // Singleton instance
    private static ICleverTapService serviceInstance;
    
    /**
     * @description Provides the CleverTap service implementation
     * @return ICleverTapService A singleton instance of the CleverTap service
     */
    public ICleverTapService provideCleverTapService() {
        if (serviceInstance == null) {
            serviceInstance = new DataProcessorImpl();
        }
        return serviceInstance;
    }
}