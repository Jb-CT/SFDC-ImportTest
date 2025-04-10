/**
 * @class TestModule
 * @description Test implementation of DIModule for use in test methods
 */
@IsTest
public class TestModule implements DIModule {
    
    // The mock service to return
    private MockCleverTapService mockService;
    
    /**
     * @description Constructor that accepts a mock service
     * @param mockService The mock service to provide
     */
    public TestModule(MockCleverTapService mockService) {
        this.mockService = mockService;
    }
    
    /**
     * @description Default constructor that creates a new mock service
     */
    public TestModule() {
        this.mockService = new MockCleverTapService();
    }
    
    /**
     * @description Provides the mock CleverTap service
     * @return ICleverTapService A mock implementation of the CleverTap service
     */
    public ICleverTapService provideCleverTapService() {
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