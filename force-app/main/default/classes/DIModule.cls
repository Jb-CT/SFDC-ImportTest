/**
 * @interface DIModule
 * @description Interface for dependency injection module
 */
public interface DIModule {
    
    /**
     * @description Provides an instance of CleverTap service
     * @return ICleverTapService An implementation of the CleverTap service
     */
    ICleverTapService provideCleverTapService();
}