import Foundation

/// Configuration model for the MiniApp SDK.
/// Contains all necessary settings for SDK initialization and operation.
public struct MiniAppConfig {
    
    // MARK: - Properties
    
    /// The base URL for the mini app server
    public let baseURL: URL
    
    /// The app identifier
    public let appId: String
    
    /// The API key for authentication
    public let apiKey: String
    
    /// The environment (development, staging, production)
    public let environment: Environment
    
    /// Timeout for network requests in seconds (default: 30)
    public let requestTimeout: TimeInterval
    
    /// Maximum number of cached mini apps (default: 10)
    public let maxCachedApps: Int
    
    /// Enable debug logging (default: false)
    public let debugLoggingEnabled: Bool
    
    /// Certificate pinning configuration (optional)
    public let certificatePinningConfig: CertificatePinningConfig?
    
    // MARK: - Environment
    
    public enum Environment: String {
        case development
        case staging
        case production
    }
    
    // MARK: - Certificate Pinning Config
    
    public struct CertificatePinningConfig {
        /// Array of public key hashes for certificate pinning
        public let publicKeyHashes: [String]
        
        public init(publicKeyHashes: [String]) {
            self.publicKeyHashes = publicKeyHashes
        }
    }
    
    // MARK: - Initializer
    
    public init(
        baseURL: URL,
        appId: String,
        apiKey: String,
        environment: Environment = .production,
        requestTimeout: TimeInterval = 30,
        maxCachedApps: Int = 10,
        debugLoggingEnabled: Bool = false,
        certificatePinningConfig: CertificatePinningConfig? = nil
    ) {
        self.baseURL = baseURL
        self.appId = appId
        self.apiKey = apiKey
        self.environment = environment
        self.requestTimeout = requestTimeout
        self.maxCachedApps = maxCachedApps
        self.debugLoggingEnabled = debugLoggingEnabled
        self.certificatePinningConfig = certificatePinningConfig
    }
    
    // MARK: - Validation
    
    /// Validate the configuration.
    /// - Throws: `MiniAppError` if the configuration is invalid.
    public func validate() throws {
        guard !appId.isEmpty else {
            throw MiniAppError.invalidConfiguration("appId cannot be empty")
        }
        guard !apiKey.isEmpty else {
            throw MiniAppError.invalidConfiguration("apiKey cannot be empty")
        }
        guard requestTimeout > 0 else {
            throw MiniAppError.invalidConfiguration("requestTimeout must be greater than 0")
        }
        guard maxCachedApps > 0 else {
            throw MiniAppError.invalidConfiguration("maxCachedApps must be greater than 0")
        }
    }
}
