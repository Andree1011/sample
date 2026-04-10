import Foundation

/// Represents an authenticated user in the Mini App SDK.
public struct User: Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for the user
    public let userId: String
    
    /// Username (display name)
    public let username: String
    
    /// Email address
    public let email: String
    
    /// Current access token
    public let accessToken: String
    
    /// Refresh token for obtaining new access tokens
    public let refreshToken: String
    
    /// Access token expiration date
    public let tokenExpiresAt: Date
    
    /// User's display name (optional)
    public let displayName: String?
    
    /// Profile picture URL (optional)
    public let avatarURL: String?
    
    /// User roles and permissions
    public let roles: [String]
    
    /// User preferences
    public let preferences: [String: String]
    
    // MARK: - Computed Properties
    
    /// Whether the user's token is expired
    public var isExpired: Bool {
        return Date() >= tokenExpiresAt
    }
    
    /// Display name with fallback to username
    public var name: String {
        return displayName ?? username
    }
    
    // MARK: - Initializer
    
    public init(
        userId: String,
        username: String,
        email: String,
        accessToken: String,
        refreshToken: String,
        tokenExpiresAt: Date,
        displayName: String? = nil,
        avatarURL: String? = nil,
        roles: [String] = [],
        preferences: [String: String] = [:]
    ) {
        self.userId = userId
        self.username = username
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpiresAt = tokenExpiresAt
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.roles = roles
        self.preferences = preferences
    }
}
