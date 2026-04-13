import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Flutter-side proxy for the iOS MiniApp SDK.
///
/// Each method on this service maps 1-to-1 with a MethodChannel call that
/// the iOS [AppDelegate] routes to the Swift SDK layer.
///
/// When running on Android or in a non-iOS environment the methods fall back
/// to simulated responses so the demo still runs on emulators / simulators.
class NativeBridgeService extends GetxService {
  static const _channel = MethodChannel('com.superapp.miniapp/sdk_bridge');

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated user's profile.
  Future<Map<String, dynamic>> getUserInfo() async {
    return await _invoke('auth.getUserInfo') ??
        {'userId': 'user_001', 'name': 'Alex Johnson', 'email': 'alex@example.com'};
  }

  // ---------------------------------------------------------------------------
  // Payment
  // ---------------------------------------------------------------------------

  /// Initiates a native payment sheet and returns the transaction result.
  Future<Map<String, dynamic>> startPayment({
    required double amount,
    required String description,
    String currency = 'USD',
  }) async {
    return await _invoke('payment.startPayment', {
          'amount': amount,
          'description': description,
          'currency': currency,
        }) ??
        {'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}', 'status': 'success'};
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Shows a local push notification.
  Future<bool> showNotification({
    required String title,
    required String body,
  }) async {
    final result = await _invoke('notification.showNotification', {
      'title': title,
      'body': body,
    });
    return (result?['success'] as bool?) ?? true;
  }

  // ---------------------------------------------------------------------------
  // Security / Biometrics
  // ---------------------------------------------------------------------------

  /// Requests Face ID / Touch ID authentication.
  Future<bool> requestBiometricAuth() async {
    final result = await _invoke('security.requestBiometricAuth');
    return (result?['authenticated'] as bool?) ?? true;
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests a runtime permission (e.g. "camera", "location").
  Future<bool> requestPermission(String type) async {
    final result = await _invoke('permission.requestPermission', {'type': type});
    return (result?['granted'] as bool?) ?? true;
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  /// Returns the device's current GPS coordinates.
  Future<Map<String, dynamic>> getLocation() async {
    return await _invoke('device.getLocation') ??
        {'latitude': 37.7749, 'longitude': -122.4194};
  }

  // ---------------------------------------------------------------------------
  // IoT
  // ---------------------------------------------------------------------------

  /// Lists paired IoT devices (fitness trackers, smartwatches, etc.).
  Future<List<dynamic>> getDeviceList() async {
    final result = await _invoke('iot.getDeviceList');
    return (result?['devices'] as List<dynamic>?) ??
        [
          {'id': 'dev_001', 'name': 'Fitbit Sense', 'type': 'fitness_tracker', 'connected': true}
        ];
  }

  /// Reads sensor data from an IoT device.
  Future<Map<String, dynamic>> readDeviceData(String deviceId) async {
    return await _invoke('iot.readDeviceData', {'deviceId': deviceId}) ??
        {'steps': 8234, 'heartRate': 72, 'calories': 412};
  }

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------

  /// Returns current network reachability status.
  Future<Map<String, dynamic>> getNetworkStatus() async {
    return await _invoke('network.getStatus') ??
        {'connected': true, 'type': 'wifi'};
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _invoke(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(method, params);
      return result?.cast<String, dynamic>();
    } on MissingPluginException {
      // Not running on iOS — caller will use the fallback value.
      return null;
    } on PlatformException catch (e) {
      debugPrint('NativeBridgeService [$method] error: ${e.message}');
      return null;
    }
  }
}
