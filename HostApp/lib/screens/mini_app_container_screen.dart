import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/mini_app.dart';
import '../models/payment.dart';
import '../services/bundle_manager.dart';
import '../services/native_bridge_service.dart';
import '../services/payment_service.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final MiniApp miniApp;

  const MiniAppContainerScreen({super.key, required this.miniApp});

  @override
  State<MiniAppContainerScreen> createState() =>
      _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  final _bundleManager = Get.find<BundleManager>();
  final _paymentService = Get.find<PaymentService>();
  final _nativeBridge = Get.find<NativeBridgeService>();

  late final WebViewController _webViewController;

  bool _isLoading = true;
  bool _webViewReady = false;
  String? _errorMessage;

  // Ids of built-in bundles shipped as Flutter assets.
  static const _builtinBundleIds = {'shopping', 'health', 'chat'};

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (err) {
          setState(() {
            _isLoading = false;
            _errorMessage = err.description;
          });
        },
      ))
      // Receive bridge calls from JavaScript
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onJsBridgeMessage,
      );
    _loadBundle();
  }

  // ---------------------------------------------------------------------------
  // Bundle loading
  // ---------------------------------------------------------------------------

  Future<void> _loadBundle() async {
    try {
      final appId = widget.miniApp.id;
      final String bundlePath;

      if (_builtinBundleIds.contains(appId)) {
        bundlePath = await _bundleManager.getBuiltinBundlePath('$appId-bundle');
      } else if (widget.miniApp.localBundlePath != null) {
        bundlePath = widget.miniApp.localBundlePath!;
      } else {
        throw Exception('No local bundle available for ${widget.miniApp.name}');
      }

      final indexFile = File('$bundlePath/index.html');
      await _webViewController.loadFile(indexFile.path);
      setState(() => _webViewReady = true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // JavaScript ↔ Flutter bridge
  // ---------------------------------------------------------------------------

  void _onJsBridgeMessage(JavaScriptMessage message) {
    try {
      final envelope = jsonDecode(message.message) as Map<String, dynamic>;
      final messageId = envelope['messageId'] as String? ?? '';
      final method = envelope['method'] as String? ?? '';
      final payload = envelope['payload'] as Map<String, dynamic>? ?? {};
      _dispatchBridgeCall(messageId, method, payload);
    } catch (e) {
      debugPrint('Bridge message parse error: $e');
    }
  }

  Future<void> _dispatchBridgeCall(
    String messageId,
    String method,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = await _handleNativeMethod(method, params);
      _sendBridgeResponse(messageId, method, result: result);
    } catch (e) {
      _sendBridgeResponse(
        messageId,
        method,
        error: {'code': 'BRIDGE_ERROR', 'message': e.toString()},
      );
    }
  }

  Future<Map<String, dynamic>> _handleNativeMethod(
    String method,
    Map<String, dynamic> params,
  ) async {
    switch (method) {
      case 'auth.getUserInfo':
        return _nativeBridge.getUserInfo();

      case 'payment.startPayment':
        final amount = (params['amount'] as num?)?.toDouble() ?? 0.0;
        final description = params['description'] as String? ?? 'Payment';
        return _handlePaymentSheet(amount, description);

      case 'notification.showNotification':
        final title = params['title'] as String? ?? 'Notification';
        final body = params['body'] as String? ?? '';
        Get.snackbar(title, body, snackPosition: SnackPosition.TOP);
        return {'success': true};

      case 'security.requestBiometricAuth':
        final granted = await _nativeBridge.requestBiometricAuth();
        return {'authenticated': granted};

      case 'permission.requestPermission':
        final type = params['type'] as String? ?? '';
        final granted = await _nativeBridge.requestPermission(type);
        return {'granted': granted};

      case 'device.getLocation':
        return _nativeBridge.getLocation();

      case 'iot.getDeviceList':
        final devices = await _nativeBridge.getDeviceList();
        return {'devices': devices};

      case 'iot.connectDevice':
        return {'connected': true};

      case 'iot.readDeviceData':
        final deviceId = params['deviceId'] as String? ?? '';
        return _nativeBridge.readDeviceData(deviceId);

      case 'network.getStatus':
        return _nativeBridge.getNetworkStatus();

      case 'storage.saveHealthMetrics':
      case 'storage.saveMessages':
        return {'saved': true};

      default:
        return {'success': true};
    }
  }

  /// Shows the native payment sheet and waits for user confirmation.
  Future<Map<String, dynamic>> _handlePaymentSheet(
    double amount,
    String description,
  ) async {
    final completer = _PaymentCompleter();
    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _PaymentSheet(
          amount: amount,
          description: description,
          onConfirm: () async {
            Navigator.pop(context);
            await _paymentService.processPayment(
              amount: amount,
              method: PaymentMethod.wallet,
              description: description,
            );
            completer.complete({
              'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
              'status': 'success',
            });
          },
          onCancel: () {
            Navigator.pop(context);
            completer.complete({'status': 'cancelled'});
          },
        ),
      );
    }
    return completer.future;
  }

  void _sendBridgeResponse(
    String correlationId,
    String method, {
    Map<String, dynamic>? result,
    Map<String, dynamic>? error,
  }) {
    final response = jsonEncode({
      'messageId': 'resp_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'response',
      'correlationId': correlationId,
      'method': method,
      if (result != null) 'payload': result,
      if (error != null) 'error': error,
    });
    final escaped = response.replaceAll("'", "\\'");
    _webViewController.runJavaScript(
        "window.MiniAppBridge && window.MiniAppBridge.handleResponse('$escaped')");
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.miniApp.emojiIcon,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(widget.miniApp.name),
          ],
        ),
        actions: [
          if (_webViewReady)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _webViewController.reload(),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showAppOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            _ErrorView(
              message: _errorMessage!,
              onRetry: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _loadBundle();
              },
            )
          else
            WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const _LoadingOverlay(),
        ],
      ),
    );
  }

  void _showAppOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                _webViewController.reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info'),
              subtitle: Text('v${widget.miniApp.version}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Uninstall',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load mini app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatelessWidget {
  final double amount;
  final String description;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PaymentSheet({
    required this.amount,
    required this.description,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payment, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          Text('Payment Request',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.green)),
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Pay Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple future completer helper
// ---------------------------------------------------------------------------

class _PaymentCompleter {
  Map<String, dynamic>? _result;
  void Function(Map<String, dynamic>)? _listener;

  Future<Map<String, dynamic>> get future async {
    if (_result != null) return _result!;
    final completer = _AsyncCompleter<Map<String, dynamic>>();
    _listener = completer.complete;
    return completer.future;
  }

  void complete(Map<String, dynamic> value) {
    _result = value;
    _listener?.call(value);
  }
}

class _AsyncCompleter<T> {
  T? _value;
  void Function(T)? _resolve;
  bool _completed = false;

  Future<T> get future async {
    if (_completed) return _value as T;
    // Poll until resolved (max 30s)
    for (var i = 0; i < 300; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_completed) return _value as T;
    }
    throw TimeoutException('Payment timed out');
  }

  void complete(T value) {
    _value = value;
    _completed = true;
    _resolve?.call(value);
  }
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
