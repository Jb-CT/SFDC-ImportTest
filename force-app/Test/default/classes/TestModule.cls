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
    
    /**
     * @description Provides the mock CleverTap service
     * @return DataProcessor A mock implementation of the CleverTap service
     */
    public DataProcessor provideCleverTapService() {
        return mockService;
    }
    
    /**
     * @description Gets the mock service for verification in tests
     * @return MockCleverTapService The mock service
     */
    public MockCleverTapService getMockService() {
        return mockService;
    }
}