import Foundation

/// Represents the manifest of a mini app.
/// Contains metadata and configuration for the app.
public struct AppManifest: Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for the mini app
    public let appId: String
    
    /// Version of the mini app
    public let version: String
    
    /// Display name of the mini app
    public let name: String
    
    /// Entry point file/URL for the mini app
    public let entryPoint: String
    
    /// Description of the mini app
    public let description: String?
    
    /// Icon URL for the mini app
    public let iconURL: String?
    
    /// Permissions required by the mini app
    public let permissions: [String]
    
    /// Minimum SDK version required
    public let minSDKVersion: String
    
    /// Maximum SDK version supported (optional)
    public let maxSDKVersion: String?
    
    /// Last updated timestamp
    public let updatedAt: Date?
    
    /// Checksum for bundle integrity verification
    public let checksum: String?
    
    /// Whether the app supports offline mode
    public let supportsOffline: Bool
    
    // MARK: - Initializer
    
    public init(
        appId: String,
        version: String,
        name: String,
        entryPoint: String,
        description: String? = nil,
        iconURL: String? = nil,
        permissions: [String] = [],
        minSDKVersion: String,
        maxSDKVersion: String? = nil,
        updatedAt: Date? = nil,
        checksum: String? = nil,
        supportsOffline: Bool = false
    ) {
        self.appId = appId
        self.version = version
        self.name = name
        self.entryPoint = entryPoint
        self.description = description
        self.iconURL = iconURL
        self.permissions = permissions
        self.minSDKVersion = minSDKVersion
        self.maxSDKVersion = maxSDKVersion
        self.updatedAt = updatedAt
        self.checksum = checksum
        self.supportsOffline = supportsOffline
    }
    
    // MARK: - Validation
    
    /// Validate the manifest.
    /// - Throws: `MiniAppError` if the manifest is invalid.
    public func validate() throws {
        guard !appId.isEmpty else {
            throw MiniAppError.invalidManifest("appId cannot be empty")
        }
        guard !version.isEmpty else {
            throw MiniAppError.invalidManifest("version cannot be empty")
        }
        guard !name.isEmpty else {
            throw MiniAppError.invalidManifest("name cannot be empty")
        }
        guard !entryPoint.isEmpty else {
            throw MiniAppError.invalidManifest("entryPoint cannot be empty")
        }
    }
}
