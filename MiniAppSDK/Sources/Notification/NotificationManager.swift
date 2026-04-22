import Foundation
import UserNotifications

/// Low-level notification manager for scheduling and managing notifications.
@available(iOS 10.0, macOS 10.14, *)
public class NotificationManager: NSObject {
    
    // MARK: - Properties
    
    private let center = UNUserNotificationCenter.current()
    private let queue = DispatchQueue(label: "com.miniapp.sdk.notifications")
    
    // MARK: - Initializer
    
    public override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Request notification authorization.
    /// - Parameter completion: Callback with granted status.
    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        queue.async { [center] in
            center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                completion(granted)
            }
        }
    }
    
    /// Schedule a local notification.
    /// - Parameters:
    ///   - notification: The notification to schedule.
    ///   - completion: Callback indicating success or failure.
    public func schedule(
        notification: LocalNotification,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        
        if let subtitle = notification.subtitle {
            content.subtitle = subtitle
        }
        
        if let badge = notification.badge {
            content.badge = NSNumber(value: badge)
        }
        
        if let soundName = notification.soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }
        
        if !notification.userInfo.isEmpty {
            content.userInfo = notification.userInfo
        }
        
        if let categoryId = notification.categoryIdentifier {
            content.categoryIdentifier = categoryId
        }
        
        let trigger: UNNotificationTrigger?
        if let scheduledDate = notification.scheduledDate {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: scheduledDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            trigger = nil // Immediate delivery
        }
        
        let request = UNNotificationRequest(
            identifier: notification.identifier,
            content: content,
            trigger: trigger
        )
        
        queue.async { [center] in
            center.add(request) { error in
                if let error = error {
                    completion(.failure(.unknown(error.localizedDescription)))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Cancel a scheduled notification.
    /// - Parameter identifier: The notification identifier to cancel.
    public func cancel(identifier: String) {
        queue.async { [center] in
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
    
    /// Cancel all pending notifications.
    public func cancelAll() {
        queue.async { [center] in
            center.removeAllPendingNotificationRequests()
        }
    }
    
    /// Get all pending notification identifiers.
    /// - Parameter completion: Callback with list of identifiers.
    public func getPendingNotifications(completion: @escaping ([String]) -> Void) {
        queue.async { [center] in
            center.getPendingNotificationRequests { requests in
                completion(requests.map { $0.identifier })
            }
        }
    }
    
    /// Clear all delivered notifications from the notification center.
    public func clearDeliveredNotifications() {
        queue.async { [center] in
            center.removeAllDeliveredNotifications()
        }
    }
    
    /// Update the app badge number.
    /// - Parameter count: The badge count (0 to clear).
    public func setBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            // UIApplication.shared.applicationIconBadgeNumber = count
            // Note: UIApplication is available in UIKit; use carefully
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
