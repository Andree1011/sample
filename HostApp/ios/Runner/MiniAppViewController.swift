import UIKit
import WebKit

/// A native iOS view controller that hosts a mini app bundle in a WKWebView
/// and wires up the MiniApp SDK bridge directly — without going through Flutter.
///
/// Use this when you want to present a mini app from a purely native iOS context
/// (e.g. from a UIKit/SwiftUI host app that does not use Flutter).
///
/// Usage:
/// ```swift
/// let vc = MiniAppViewController(bundlePath: "/path/to/shopping-bundle")
/// navigationController?.pushViewController(vc, animated: true)
/// ```
public final class MiniAppViewController: UIViewController {

    // MARK: - Properties

    private let bundlePath: String
    private let appName: String
    private var webView: WKWebView!
    private var progressBar: UIProgressView!
    private var progressObservation: NSKeyValueObservation?

    // MARK: - Init

    public init(bundlePath: String, appName: String = "Mini App") {
        self.bundlePath = bundlePath
        self.appName = appName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = appName
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupWebView()
        setupProgressBar()
        loadBundle()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        progressObservation?.invalidate()
        // Remove the message handler to prevent retain cycles
        webView.configuration.userContentController
            .removeScriptMessageHandler(forName: "FlutterBridge")
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(reloadTapped)
        )
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Register the bridge message handler
        let contentController = config.userContentController
        contentController.add(self, name: "FlutterBridge")

        // Inject bridge initialisation script before page JS runs
        let bridgeInit = WKUserScript(
            source: bridgeInitScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        contentController.addUserScript(bridgeInit)

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupProgressBar() {
        progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = UIColor(red: 0.42, green: 0.38, blue: 1.0, alpha: 1)
        view.addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])

        progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            DispatchQueue.main.async {
                let p = Float(wv.estimatedProgress)
                self?.progressBar.setProgress(p, animated: true)
                self?.progressBar.isHidden = p >= 1.0
            }
        }
    }

    // MARK: - Loading

    private func loadBundle() {
        let indexURL = URL(fileURLWithPath: "\(bundlePath)/index.html")
        let bundleDirectory = URL(fileURLWithPath: bundlePath)
        webView.loadFileURL(indexURL, allowingReadAccessTo: bundleDirectory)
    }

    @objc private func reloadTapped() {
        webView.reload()
    }

    // MARK: - Bridge script

    /// JavaScript injected at document start so that `window.MiniAppBridge`
    /// and `window.MiniApp` are available before any app JS runs.
    private func bridgeInitScript() -> String {
        return """
        window.MiniAppBridge = {
            _callbacks: {},
            _eventListeners: {},
            callNative: function(method, params) {
                return new Promise(function(resolve, reject) {
                    var messageId = 'msg_' + Math.random().toString(36).substr(2, 11);
                    this._callbacks[messageId] = { resolve: resolve, reject: reject };
                    var envelope = JSON.stringify({ messageId: messageId, method: method, payload: params || {} });
                    window.webkit.messageHandlers.FlutterBridge.postMessage(envelope);
                    setTimeout(function() {
                        if (window.MiniAppBridge._callbacks[messageId]) {
                            delete window.MiniAppBridge._callbacks[messageId];
                            reject(new Error('Timeout: ' + method));
                        }
                    }, 30000);
                }.bind(this));
            },
            handleResponse: function(jsonString) {
                try {
                    var data = JSON.parse(jsonString);
                    var cb = this._callbacks[data.correlationId];
                    if (cb) {
                        delete this._callbacks[data.correlationId];
                        data.error ? cb.reject(new Error(data.error.message)) : cb.resolve(data.payload || {});
                    }
                } catch(e) { console.error('Bridge parse error', e); }
            },
            onEvent: function(event, callback) {
                if (!this._eventListeners[event]) this._eventListeners[event] = [];
                this._eventListeners[event].push(callback);
            },
            dispatchEvent: function(event, data) {
                (this._eventListeners[event] || []).forEach(function(fn){ fn(data); });
            }
        };

        window.MiniApp = {
            auth: { getUserInfo: function() { return MiniAppBridge.callNative('auth.getUserInfo'); } },
            payment: { startPayment: function(p) { return MiniAppBridge.callNative('payment.startPayment', p); } },
            notification: {
                showNotification: function(p) { return MiniAppBridge.callNative('notification.showNotification', p); },
                onPushReceived: function(cb) { return MiniAppBridge.onEvent('pushNotification', cb); }
            },
            device: { getLocation: function() { return MiniAppBridge.callNative('device.getLocation'); } },
            security: { requestBiometricAuth: function() { return MiniAppBridge.callNative('security.requestBiometricAuth'); } },
            permission: { requestPermission: function(t) { return MiniAppBridge.callNative('permission.requestPermission', { type: t }); } },
            iot: {
                getDeviceList: function() { return MiniAppBridge.callNative('iot.getDeviceList'); },
                connectDevice: function(id) { return MiniAppBridge.callNative('iot.connectDevice', { deviceId: id }); },
                readDeviceData: function(id) { return MiniAppBridge.callNative('iot.readDeviceData', { deviceId: id }); }
            },
            storage: {
                saveHealthMetrics: function(d) { return MiniAppBridge.callNative('storage.saveHealthMetrics', d); },
                saveMessages: function(d) { return MiniAppBridge.callNative('storage.saveMessages', d); }
            },
            network: { getStatus: function() { return MiniAppBridge.callNative('network.getStatus'); } }
        };
        """
    }

    // MARK: - Bridge response helper

    private func sendResponse(correlationId: String, method: String, payload: [String: Any]?, error: String?) {
        var responseDict: [String: Any] = [
            "messageId": UUID().uuidString,
            "type": "response",
            "correlationId": correlationId,
            "method": method
        ]
        if let payload = payload { responseDict["payload"] = payload }
        if let error = error { responseDict["error"] = ["code": "BRIDGE_ERROR", "message": error] }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: responseDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let escaped = jsonString.replacingOccurrences(of: "'", with: "\\'")
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("window.MiniAppBridge.handleResponse('\(escaped)')", completionHandler: nil)
        }
    }
}

// MARK: - WKNavigationDelegate

extension MiniAppViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showErrorAlert(error.localizedDescription)
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showErrorAlert(error.localizedDescription)
    }

    private func showErrorAlert(_ message: String) {
        let alert = UIAlertController(
            title: "Failed to load",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in self?.loadBundle() })
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in self?.navigationController?.popViewController(animated: true) })
        present(alert, animated: true)
    }
}

// MARK: - WKScriptMessageHandler

extension MiniAppViewController: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "FlutterBridge",
              let body = message.body as? String,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let messageId = json["messageId"] as? String ?? UUID().uuidString
        let method    = json["method"]    as? String ?? ""
        let params    = json["payload"]   as? [String: Any] ?? [:]

        handleNativeCall(messageId: messageId, method: method, params: params)
    }

    private func handleNativeCall(messageId: String, method: String, params: [String: Any]) {
        switch method {
        case "auth.getUserInfo":
            sendResponse(correlationId: messageId, method: method,
                         payload: ["userId": "user_001", "name": "Alex Johnson", "email": "alex@example.com"],
                         error: nil)

        case "payment.startPayment":
            let amount      = params["amount"]      as? Double ?? 0
            let description = params["description"] as? String ?? "Payment"
            showPaymentSheet(amount: amount, description: description) { [weak self] txnId in
                self?.sendResponse(correlationId: messageId, method: method,
                                   payload: ["transactionId": txnId, "status": "success"],
                                   error: nil)
            }

        case "notification.showNotification":
            let title = params["title"] as? String ?? "Notification"
            let body  = params["body"]  as? String ?? ""
            showToast("\(title): \(body)")
            sendResponse(correlationId: messageId, method: method, payload: ["success": true], error: nil)

        case "security.requestBiometricAuth":
            sendResponse(correlationId: messageId, method: method, payload: ["authenticated": true], error: nil)

        case "permission.requestPermission":
            sendResponse(correlationId: messageId, method: method, payload: ["granted": true], error: nil)

        case "device.getLocation":
            sendResponse(correlationId: messageId, method: method,
                         payload: ["latitude": 37.7749, "longitude": -122.4194], error: nil)

        case "iot.getDeviceList":
            sendResponse(correlationId: messageId, method: method,
                         payload: ["devices": [["id": "dev_001", "name": "Fitbit Sense", "type": "fitness_tracker"]]],
                         error: nil)

        case "iot.readDeviceData":
            sendResponse(correlationId: messageId, method: method,
                         payload: ["steps": 8234, "heartRate": 72, "calories": 412], error: nil)

        case "network.getStatus":
            sendResponse(correlationId: messageId, method: method,
                         payload: ["connected": true, "type": "wifi"], error: nil)

        default:
            sendResponse(correlationId: messageId, method: method, payload: ["success": true], error: nil)
        }
    }

    // MARK: - UI helpers

    private func showPaymentSheet(amount: Double, description: String, completion: @escaping (String) -> Void) {
        let formatted = String(format: "$%.2f", amount)
        let alert = UIAlertController(
            title: "Payment Request",
            message: "\(description)\n\nAmount: \(formatted)",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Pay \(formatted)", style: .default) { _ in
            completion("txn_\(Int(Date().timeIntervalSince1970 * 1000))")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showToast(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        UIView.animate(withDuration: 0.3, delay: 2.0, options: .curveEaseOut) {
            label.alpha = 0
        } completion: { _ in label.removeFromSuperview() }
    }
}
