import Foundation

/// High-level notification service for managing notifications in the SDK.
public class NotificationService {
    
    // MARK: - Properties
    
    private let notificationManager: NotificationManager
    private var isAuthorized: Bool = false
    
    // MARK: - Initializer
    
    public init() {
        self.notificationManager = NotificationManager()
    }
    
    // MARK: - Public Methods
    
    /// Initialize the notification service and request authorization.
    /// - Parameter completion: Callback with authorization status.
    public func initialize(completion: @escaping (Bool) -> Void) {
        notificationManager.requestAuthorization { [weak self] granted in
            self?.isAuthorized = granted
            completion(granted)
        }
    }
    
    /// Schedule a local notification.
    /// - Parameters:
    ///   - title: Notification title.
    ///   - body: Notification body.
    ///   - scheduledDate: Delivery date (nil for immediate).
    ///   - userInfo: Additional data.
    ///   - completion: Callback with notification identifier or error.
    public func scheduleNotification(
        title: String,
        body: String,
        scheduledDate: Date? = nil,
        userInfo: [String: Any] = [:],
        completion: @escaping (Result<String, MiniAppError>) -> Void
    ) {
        let notification = LocalNotification(
            title: title,
            body: body,
            userInfo: userInfo,
            scheduledDate: scheduledDate
        )
        
        notificationManager.schedule(notification: notification) { result in
            switch result {
            case .success:
                completion(.success(notification.identifier))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Cancel a scheduled notification by identifier.
    /// - Parameter identifier: The notification identifier.
    public func cancelNotification(identifier: String) {
        notificationManager.cancel(identifier: identifier)
    }
    
    /// Cancel all pending notifications.
    public func cancelAllNotifications() {
        notificationManager.cancelAll()
    }
    
    /// Get all pending notification identifiers.
    /// - Parameter completion: Callback with list of identifiers.
    public func getPendingNotifications(completion: @escaping ([String]) -> Void) {
        notificationManager.getPendingNotifications(completion: completion)
    }
    
    /// Schedule a notification with full configuration.
    /// - Parameters:
    ///   - notification: The fully configured `LocalNotification`.
    ///   - completion: Callback indicating success or failure.
    public func schedule(
        notification: LocalNotification,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        notificationManager.schedule(notification: notification, completion: completion)
    }
    
    /// Clear all delivered notifications from the notification center.
    public func clearDeliveredNotifications() {
        notificationManager.clearDeliveredNotifications()
    }
}
