import Foundation

/// Custom error types for the MiniApp SDK.
public enum MiniAppError: Error, LocalizedError, Equatable {
    
    // MARK: - Core Errors
    
    /// The SDK has not been initialized
    case notInitialized
    
    /// The SDK has already been initialized
    case alreadyInitialized
    
    /// Invalid configuration provided
    case invalidConfiguration(String)
    
    // MARK: - Loading Errors
    
    /// Mini app not found
    case appNotFound(String)
    
    /// Failed to load mini app
    case loadFailed(String)
    
    /// App manifest is invalid or malformed
    case invalidManifest(String)
    
    /// App version mismatch
    case versionMismatch(String)
    
    // MARK: - Cache Errors
    
    /// Cache miss - item not found in cache
    case cacheMiss
    
    /// Cache storage failed
    case cacheWriteFailed(String)
    
    /// Cache is full
    case cacheFull
    
    // MARK: - Authentication Errors
    
    /// User is not authenticated
    case notAuthenticated
    
    /// Authentication failed
    case authenticationFailed(String)
    
    /// Token has expired
    case tokenExpired
    
    /// Token refresh failed
    case tokenRefreshFailed(String)
    
    /// Invalid credentials
    case invalidCredentials
    
    // MARK: - Security Errors
    
    /// Biometric authentication not available
    case biometricNotAvailable
    
    /// Biometric authentication failed
    case biometricFailed(String)
    
    /// Permission denied
    case permissionDenied(String)
    
    /// Permission not determined
    case permissionNotDetermined(String)
    
    // MARK: - Network Errors
    
    /// Network request failed
    case networkFailed(String)
    
    /// No internet connection
    case noInternetConnection
    
    /// Request timeout
    case requestTimeout
    
    /// Invalid URL
    case invalidURL(String)
    
    /// Server error with HTTP status code
    case serverError(Int, String)
    
    /// Certificate pinning validation failed
    case certificatePinningFailed
    
    // MARK: - Payment Errors
    
    /// Payment processing failed
    case paymentFailed(String)
    
    /// Transaction not found
    case transactionNotFound(String)
    
    /// Invalid payment amount
    case invalidPaymentAmount
    
    // MARK: - IoT Errors
    
    /// Bluetooth not available
    case bluetoothNotAvailable
    
    /// Device not found
    case deviceNotFound(String)
    
    /// Device connection failed
    case deviceConnectionFailed(String)
    
    // MARK: - Bridge Errors
    
    /// Bridge not initialized
    case bridgeNotInitialized
    
    /// Method not found on bridge
    case bridgeMethodNotFound(String)
    
    /// Bridge message failed
    case bridgeMessageFailed(String)
    
    // MARK: - General Errors
    
    /// Unknown error occurred
    case unknown(String)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "MiniApp SDK has not been initialized. Call MiniAppManager.shared.initialize(with:) first."
        case .alreadyInitialized:
            return "MiniApp SDK has already been initialized."
        case .invalidConfiguration(let message):
            return "Invalid SDK configuration: \(message)"
        case .appNotFound(let appId):
            return "Mini app not found: \(appId)"
        case .loadFailed(let message):
            return "Failed to load mini app: \(message)"
        case .invalidManifest(let message):
            return "Invalid app manifest: \(message)"
        case .versionMismatch(let message):
            return "App version mismatch: \(message)"
        case .cacheMiss:
            return "Item not found in cache."
        case .cacheWriteFailed(let message):
            return "Cache write failed: \(message)"
        case .cacheFull:
            return "Cache is full. Please clear some entries."
        case .notAuthenticated:
            return "User is not authenticated. Please sign in."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .tokenExpired:
            return "Authentication token has expired."
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .invalidCredentials:
            return "Invalid credentials provided."
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .permissionNotDetermined(let permission):
            return "Permission not determined: \(permission)"
        case .networkFailed(let message):
            return "Network request failed: \(message)"
        case .noInternetConnection:
            return "No internet connection available."
        case .requestTimeout:
            return "Network request timed out."
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .certificatePinningFailed:
            return "Certificate pinning validation failed."
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .transactionNotFound(let id):
            return "Transaction not found: \(id)"
        case .invalidPaymentAmount:
            return "Invalid payment amount specified."
        case .bluetoothNotAvailable:
            return "Bluetooth is not available on this device."
        case .deviceNotFound(let deviceId):
            return "IoT Device not found: \(deviceId)"
        case .deviceConnectionFailed(let message):
            return "Device connection failed: \(message)"
        case .bridgeNotInitialized:
            return "MiniApp Bridge has not been initialized."
        case .bridgeMethodNotFound(let method):
            return "Bridge method not found: \(method)"
        case .bridgeMessageFailed(let message):
            return "Bridge message failed: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: MiniAppError, rhs: MiniAppError) -> Bool {
        return lhs.errorDescription == rhs.errorDescription
    }
}
