import Foundation
import WebKit

/// Communication bridge between the host app and mini apps.
/// Uses WKWebView JavaScript bridge for message passing.
public class MiniAppBridge: NSObject {
    
    // MARK: - Properties
    
    private weak var webView: WKWebView?
    private let methodInvoker: MethodInvoker
    private var pendingCallbacks: [String: (Result<[String: Any], MiniAppError>) -> Void] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.bridge", attributes: .concurrent)
    private var isInitialized = false
    
    /// Bridge message handler name in JavaScript
    private static let bridgeHandlerName = "miniAppBridge"
    
    // MARK: - Initializer
    
    public init(methodInvoker: MethodInvoker = MethodInvoker()) {
        self.methodInvoker = methodInvoker
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Initialize the bridge with a WKWebView.
    /// - Parameter webView: The web view to attach the bridge to.
    public func initialize(with webView: WKWebView) {
        self.webView = webView
        
        // Add message handler for bridge communication
        webView.configuration.userContentController.add(self, name: Self.bridgeHandlerName)
        
        // Inject bridge JavaScript
        injectBridgeScript(into: webView)
        
        isInitialized = true
        
        // Register default methods
        registerDefaultMethods()
    }
    
    /// Tear down the bridge from the web view.
    public func teardown() {
        webView?.configuration.userContentController.removeScriptMessageHandler(
            forName: Self.bridgeHandlerName
        )
        webView = nil
        isInitialized = false
        
        queue.async(flags: .barrier) { [weak self] in
            self?.pendingCallbacks.removeAll()
        }
    }
    
    /// Register a native method handler accessible from JavaScript.
    /// - Parameters:
    ///   - method: The method name.
    ///   - handler: The handler closure.
    public func register(method: String, handler: @escaping MethodInvoker.MethodHandler) {
        methodInvoker.register(method: method, handler: handler)
    }
    
    /// Send an event to the mini app (JavaScript side).
    /// - Parameters:
    ///   - eventName: The event name.
    ///   - data: The event data.
    public func sendEvent(eventName: String, data: [String: Any]) {
        guard isInitialized else { return }
        
        let message = BridgeMessage(
            type: .event,
            method: eventName,
            source: "host"
        )
        
        let jsonData: [String: Any] = [
            "messageId": message.messageId,
            "type": message.type.rawValue,
            "method": eventName,
            "payload": data
        ]
        
        sendToWebView(jsonData)
    }
    
    /// Call a JavaScript method in the mini app.
    /// - Parameters:
    ///   - method: The JavaScript method name.
    ///   - parameters: Parameters to pass to the method.
    ///   - completion: Callback with the result.
    public func callMethod(
        method: String,
        parameters: [String: Any] = [:],
        completion: ((Result<Any, MiniAppError>) -> Void)? = nil
    ) {
        guard let webView = webView else {
            completion?(.failure(.bridgeNotInitialized))
            return
        }
        
        var jsCall = "\(method)("
        if !parameters.isEmpty,
           let jsonData = try? JSONSerialization.data(withJSONObject: parameters),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            jsCall += jsonString
        }
        jsCall += ")"
        
        DispatchQueue.main.async {
            webView.evaluateJavaScript(jsCall) { result, error in
                if let error = error {
                    completion?(.failure(.bridgeMessageFailed(error.localizedDescription)))
                } else {
                    completion?(.success(result ?? NSNull()))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func injectBridgeScript(into webView: WKWebView) {
        let bridgeScript = """
        window.MiniAppBridge = {
            nativeCall: function(method, params, callback) {
                var message = {
                    messageId: Math.random().toString(36).substr(2, 9),
                    type: 'request',
                    method: method,
                    payload: params || {}
                };
                window.webkit.messageHandlers.\(Self.bridgeHandlerName).postMessage(JSON.stringify(message));
                if (callback) {
                    window._miniAppBridgeCallbacks = window._miniAppBridgeCallbacks || {};
                    window._miniAppBridgeCallbacks[message.messageId] = callback;
                }
                return message.messageId;
            },
            handleResponse: function(responseJson) {
                var response = JSON.parse(responseJson);
                if (response.correlationId && window._miniAppBridgeCallbacks) {
                    var callback = window._miniAppBridgeCallbacks[response.correlationId];
                    if (callback) {
                        callback(response.payload, response.error);
                        delete window._miniAppBridgeCallbacks[response.correlationId];
                    }
                }
            }
        };
        """
        
        let userScript = WKUserScript(
            source: bridgeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        webView.configuration.userContentController.addUserScript(userScript)
    }
    
    private func registerDefaultMethods() {
        // Register a ping method for connectivity testing
        register(method: "ping") { _, completion in
            completion(.success(["status": "pong", "timestamp": Date().timeIntervalSince1970]))
        }
        
        // Register SDK version method
        register(method: "getSDKVersion") { _, completion in
            completion(.success(["version": "1.0.0"]))
        }
    }
    
    private func sendToWebView(_ data: [String: Any]) {
        guard let webView = webView,
              let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let js = "window.MiniAppBridge && window.MiniAppBridge.handleResponse('\(jsonString.replacingOccurrences(of: "'", with: "\\'"))')"
        
        DispatchQueue.main.async {
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}

// MARK: - WKScriptMessageHandler

extension MiniAppBridge: WKScriptMessageHandler {
    
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.bridgeHandlerName,
              let body = message.body as? String,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }
        
        let messageId = json["messageId"] as? String ?? UUID().uuidString
        let method = json["method"] as? String ?? ""
        let payload = json["payload"] as? [String: Any] ?? [:]
        
        methodInvoker.invoke(method: method, parameters: payload) { [weak self] result in
            guard let self = self else { return }
            
            var responseData: [String: Any] = [
                "messageId": UUID().uuidString,
                "type": BridgeMessage.MessageType.response.rawValue,
                "correlationId": messageId,
                "method": method
            ]
            
            switch result {
            case .success(let responsePayload):
                responseData["payload"] = responsePayload
            case .failure(let error):
                responseData["error"] = [
                    "code": "BRIDGE_ERROR",
                    "message": error.errorDescription ?? "Unknown error"
                ]
            }
            
            self.sendToWebView(responseData)
        }
    }
}
