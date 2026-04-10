import Foundation

/// Central manager for all SDK operations.
/// Provides initialization, configuration, and dependency injection for the MiniApp SDK.
public class MiniAppManager {
    
    // MARK: - Singleton
    
    /// Shared instance of MiniAppManager
    public static let shared = MiniAppManager()
    
    // MARK: - Properties
    
    private(set) var config: MiniAppConfig?
    private(set) var isInitialized: Bool = false
    
    private let queue = DispatchQueue(label: "com.miniapp.sdk.manager", attributes: .concurrent)
    
    /// The loader instance used for loading mini apps
    public private(set) lazy var loader: MiniAppLoader = MiniAppLoader()
    
    /// The cache manager for storing mini app bundles
    public private(set) lazy var cacheManager: CacheManager = CacheManager()
    
    /// The authentication service
    public private(set) lazy var authService: AuthenticationService = AuthenticationService()
    
    /// The network service
    public private(set) lazy var networkService: NetworkService = NetworkService()
    
    /// The notification service
    public private(set) lazy var notificationService: NotificationService = NotificationService()
    
    /// The payment service
    public private(set) lazy var paymentService: PaymentService = PaymentService()
    
    /// The IoT service
    public private(set) lazy var iotService: IoTService = IoTService()
    
    /// The security permission manager
    public private(set) lazy var permissionManager: PermissionManager = PermissionManager()
    
    /// The biometric service
    public private(set) lazy var biometricService: BiometricService = BiometricService()
    
    // MARK: - Initializer
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Initialize the SDK with a given configuration.
    /// - Parameter config: The configuration to use for the SDK.
    /// - Throws: `MiniAppError` if initialization fails.
    public func initialize(with config: MiniAppConfig) throws {
        guard !isInitialized else {
            throw MiniAppError.alreadyInitialized
        }
        
        try config.validate()
        
        queue.async(flags: .barrier) { [weak self] in
            self?.config = config
            self?.isInitialized = true
        }
    }
    
    /// Reset the SDK to its initial state.
    public func reset() {
        queue.async(flags: .barrier) { [weak self] in
            self?.config = nil
            self?.isInitialized = false
        }
    }
    
    /// Get the current SDK configuration.
    /// - Returns: The current `MiniAppConfig`, or nil if not initialized.
    public func getConfig() -> MiniAppConfig? {
        return queue.sync { config }
    }
    
    /// Check if the SDK has been initialized.
    /// - Returns: `true` if initialized, `false` otherwise.
    public func checkInitialized() throws {
        guard queue.sync(execute: { isInitialized }) else {
            throw MiniAppError.notInitialized
        }
    }
}
