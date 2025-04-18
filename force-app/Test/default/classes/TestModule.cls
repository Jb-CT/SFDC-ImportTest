/**
 * @class TestModule
 * @description Test implementation of DIModule for use in test methods
 */
@IsTest
public class TestModule implements DIModule {
    private final MockCleverTapService mockService;
    
    /**
     * @description Constructor that accepts a mock service
     * @param mockService The mock service to provide
     */
    public TestModule(MockCleverTapService mockService) {
        this.mockService = mockService;
    }

    /**
     * @description Default constructor
     */
    public TestModule() {
        this.mockService = new MockCleverTapService();
    }
    
    /**
     * @description Provides an instance of IntegrationHandler
     * @return IntegrationHandler An instance of the integration handler
     */
    public IntegrationHandler provideIntegrationHandler() {
        return new IntegrationHandler(this);
    }
    
    /**
     * @description Provides the mock CleverTap service
     * @return DataProcessor A mock implementation of the CleverTap service
     */
    public DataProcessor provideCleverTapService() {
        return mockService;
    }
    
    /**
     * @description Provides an instance of EntityTransformer for testing
     * @return EntityTransformer A mock or test implementation of EntityTransformer
     */
    public EntityTransformer provideEntityTransformer() {
        return new EntityTransformer();
    }
    
    /**
     * @description Provides an instance of Config for testing
     * @return Config A mock or test implementation of Config
     */
    public Config provideConfig() {
        return new Config();
    }
    
    /**
     * @description Provides an instance of ResultLogger for testing
     * @return ResultLogger A mock or test implementation of ResultLogger
     */
    public ResultLogger provideResultLogger() {
        return new ResultLogger();
    }
    
    /**
     * @description Gets the mock service for verification in tests
     * @return MockCleverTapService The mock service
     */
    public MockCleverTapService getMockService() {
        return mockService;
    }
}