/**
 * @interface DIModule
 * @description Interface for dependency injection module
 */
public interface DIModule {
    /**
     * @description Provides an instance of CleverTap service
     * @return DataProcessor An implementation of the CleverTap service
     */
    DataProcessor provideCleverTapService();
}