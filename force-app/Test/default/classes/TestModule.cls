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

    public TestModule() {
        this.mockService = new MockCleverTapService();
    }

    public IntegrationHandler provideIntegrationHandler() {
        return new IntegrationHandler(this);
    }

    public DataProcessor provideCleverTapService() {
        return mockService;
    }

    public EntityTransformer provideEntityTransformer() {
        return new EntityTransformer();
    }

    public Config provideConfig() {
        return new Config();
    }

    public ResultLogger provideResultLogger() {
        return new ResultLogger();
    }

    public MockCleverTapService getMockService() {
        return mockService;
    }
}