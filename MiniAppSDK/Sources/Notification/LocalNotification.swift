import Foundation

/// Represents a local notification model.
public struct LocalNotification {
    
    // MARK: - Properties
    
    /// Unique identifier for the notification
    public let identifier: String
    
    /// Notification title
    public let title: String
    
    /// Notification body message
    public let body: String
    
    /// Optional subtitle
    public let subtitle: String?
    
    /// Optional badge number
    public let badge: Int?
    
    /// Optional sound name (nil = default sound)
    public let soundName: String?
    
    /// User info dictionary for additional data
    public let userInfo: [String: Any]
    
    /// Scheduled delivery date (nil = immediate)
    public let scheduledDate: Date?
    
    /// Category identifier for action buttons
    public let categoryIdentifier: String?
    
    // MARK: - Initializer
    
    public init(
        identifier: String = UUID().uuidString,
        title: String,
        body: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        soundName: String? = nil,
        userInfo: [String: Any] = [:],
        scheduledDate: Date? = nil,
        categoryIdentifier: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.badge = badge
        self.soundName = soundName
        self.userInfo = userInfo
        self.scheduledDate = scheduledDate
        self.categoryIdentifier = categoryIdentifier
    }
}
