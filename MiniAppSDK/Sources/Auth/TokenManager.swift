import Foundation

/// Manages authentication tokens including refresh, validation, and expiry.
public class TokenManager {
    
    // MARK: - Properties
    
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?
    private let queue = DispatchQueue(label: "com.miniapp.sdk.token", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Store tokens in memory.
    /// - Parameters:
    ///   - accessToken: The access token.
    ///   - refreshToken: The refresh token.
    ///   - expiresAt: Token expiration date.
    public func storeTokens(accessToken: String, refreshToken: String, expiresAt: Date) {
        queue.async(flags: .barrier) { [weak self] in
            self?.accessToken = accessToken
            self?.refreshToken = refreshToken
            self?.tokenExpiresAt = expiresAt
        }
    }
    
    /// Get the current access token.
    /// - Returns: The access token, or nil if not available.
    public func getAccessToken() -> String? {
        return queue.sync { accessToken }
    }
    
    /// Get the current refresh token.
    /// - Returns: The refresh token, or nil if not available.
    public func getRefreshToken() -> String? {
        return queue.sync { refreshToken }
    }
    
    /// Check if the current access token is expired.
    /// - Returns: `true` if expired or no token exists.
    public func isTokenExpired() -> Bool {
        return queue.sync {
            guard let expiresAt = tokenExpiresAt else { return true }
            return Date() >= expiresAt
        }
    }
    
    /// Validate the current access token.
    /// - Returns: `true` if token is valid (exists and not expired).
    public func isTokenValid() -> Bool {
        return queue.sync {
            guard accessToken != nil else { return false }
            return !isTokenExpired()
        }
    }
    
    /// Refresh the access token using the refresh token.
    /// - Parameters:
    ///   - currentToken: The current refresh token.
    ///   - completion: Callback with new access token or an error.
    public func refreshToken(
        currentToken: String,
        completion: @escaping (Result<String, MiniAppError>) -> Void
    ) {
        // In production, this would make an API call to refresh the token
        guard !currentToken.isEmpty else {
            completion(.failure(.tokenRefreshFailed("Empty refresh token")))
            return
        }
        
        // Simulate token refresh
        let newToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let newExpiresAt = Date().addingTimeInterval(3600)
        
        queue.async(flags: .barrier) { [weak self] in
            self?.accessToken = newToken
            self?.tokenExpiresAt = newExpiresAt
        }
        
        completion(.success(newToken))
    }
    
    /// Clear all stored tokens.
    public func clearTokens() {
        queue.async(flags: .barrier) { [weak self] in
            self?.accessToken = nil
            self?.refreshToken = nil
            self?.tokenExpiresAt = nil
        }
    }
    
    /// Get the time remaining before token expiration.
    /// - Returns: Remaining time in seconds, or 0 if expired.
    public func timeUntilExpiration() -> TimeInterval {
        return queue.sync {
            guard let expiresAt = tokenExpiresAt else { return 0 }
            return max(0, expiresAt.timeIntervalSinceNow)
        }
    }
}
