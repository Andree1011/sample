import Flutter
import LocalAuthentication
import UserNotifications

/// Handles all MethodChannel calls from the Flutter layer and routes them
/// to the appropriate native iOS service.
///
/// Each `case` maps directly to a method in `NativeBridgeService.dart`.
final class MiniAppBridgeChannel: NSObject {

    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        channel.setMethodCallHandler(handle)
    }

    // MARK: - Dispatch

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "auth.getUserInfo":
            handleGetUserInfo(result: result)
        case "payment.startPayment":
            handleStartPayment(args: args, result: result)
        case "notification.showNotification":
            handleShowNotification(args: args, result: result)
        case "security.requestBiometricAuth":
            handleBiometricAuth(result: result)
        case "permission.requestPermission":
            handleRequestPermission(args: args, result: result)
        case "device.getLocation":
            handleGetLocation(result: result)
        case "iot.getDeviceList":
            handleGetDeviceList(result: result)
        case "iot.connectDevice":
            result(["connected": true])
        case "iot.readDeviceData":
            handleReadDeviceData(args: args, result: result)
        case "network.getStatus":
            result(["connected": true, "type": "wifi"])
        case "storage.saveHealthMetrics", "storage.saveMessages":
            result(["saved": true])
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Auth

    private func handleGetUserInfo(result: FlutterResult) {
        result([
            "userId": "user_001",
            "name": "Alex Johnson",
            "email": "alex@example.com"
        ])
    }

    // MARK: - Payment

    private func handleStartPayment(args: [String: Any], result: @escaping FlutterResult) {
        // In production this would open a native payment sheet (Apple Pay, etc.)
        // For the demo, we return a simulated success immediately.
        let txnId = "txn_\(Int(Date().timeIntervalSince1970 * 1000))"
        result(["transactionId": txnId, "status": "success"])
    }

    // MARK: - Notifications

    private func handleShowNotification(args: [String: Any], result: @escaping FlutterResult) {
        let title = args["title"] as? String ?? "Notification"
        let body  = args["body"]  as? String ?? ""

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request) { _ in }
        result(["success": true])
    }

    // MARK: - Biometrics

    private func handleBiometricAuth(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics unavailable — succeed in the demo
            result(["authenticated": true])
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to continue"
        ) { success, _ in
            DispatchQueue.main.async {
                result(["authenticated": success])
            }
        }
    }

    // MARK: - Permissions

    private func handleRequestPermission(args: [String: Any], result: FlutterResult) {
        // Real permission requests would use CLLocationManager, AVCaptureDevice, etc.
        // Return granted for the demo.
        result(["granted": true])
    }

    // MARK: - Location

    private func handleGetLocation(result: FlutterResult) {
        // Return a mock San Francisco location for the demo.
        result(["latitude": 37.7749, "longitude": -122.4194])
    }

    // MARK: - IoT

    private func handleGetDeviceList(result: FlutterResult) {
        result([
            "devices": [
                ["id": "dev_001", "name": "Fitbit Sense", "type": "fitness_tracker", "connected": true, "battery": 78]
            ]
        ])
    }

    private func handleReadDeviceData(args: [String: Any], result: FlutterResult) {
        result(["steps": 8234, "heartRate": 72, "calories": 412])
    }
}
