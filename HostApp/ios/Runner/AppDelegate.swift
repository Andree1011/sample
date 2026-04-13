import Flutter
import UIKit
import LocalAuthentication

/// Main iOS entry point for the SuperApp Flutter host.
///
/// Registers all MethodChannel handlers that bridge Flutter Dart calls to
/// iOS-native functionality (biometrics, notifications, payments, etc.).
/// In a production build these handlers would delegate to the MiniApp SDK.
@main
@objc class AppDelegate: FlutterAppDelegate {

    private let channelName = "com.superapp.miniapp/sdk_bridge"
    private var bridgeChannel: MiniAppBridgeChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Set up the SDK bridge method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            let methodChannel = FlutterMethodChannel(
                name: channelName,
                binaryMessenger: controller.binaryMessenger
            )
            bridgeChannel = MiniAppBridgeChannel(channel: methodChannel)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
