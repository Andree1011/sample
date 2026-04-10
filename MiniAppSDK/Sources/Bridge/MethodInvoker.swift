import Foundation

/// Handles method invocation via the Mini App Bridge.
/// Routes bridge method calls to registered handlers.
public class MethodInvoker {
    
    // MARK: - Types
    
    /// Handler for bridge method calls
    public typealias MethodHandler = ([String: Any], @escaping (Result<[String: Any], MiniAppError>) -> Void) -> Void
    
    // MARK: - Properties
    
    private var methodHandlers: [String: MethodHandler] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.methodinvoker", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Register a handler for a specific method name.
    /// - Parameters:
    ///   - method: The method name to handle.
    ///   - handler: The handler closure.
    public func register(method: String, handler: @escaping MethodHandler) {
        queue.async(flags: .barrier) { [weak self] in
            self?.methodHandlers[method] = handler
        }
    }
    
    /// Unregister a handler for a specific method name.
    /// - Parameter method: The method name to unregister.
    public func unregister(method: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.methodHandlers.removeValue(forKey: method)
        }
    }
    
    /// Invoke a registered method.
    /// - Parameters:
    ///   - method: The method name to invoke.
    ///   - parameters: The parameters to pass to the method.
    ///   - completion: Callback with the result or an error.
    public func invoke(
        method: String,
        parameters: [String: Any],
        completion: @escaping (Result<[String: Any], MiniAppError>) -> Void
    ) {
        guard let handler = queue.sync(execute: { methodHandlers[method] }) else {
            completion(.failure(.bridgeMethodNotFound(method)))
            return
        }
        
        handler(parameters, completion)
    }
    
    /// Check if a method is registered.
    /// - Parameter method: The method name to check.
    /// - Returns: `true` if the method is registered.
    public func isMethodRegistered(_ method: String) -> Bool {
        return queue.sync { methodHandlers[method] != nil }
    }
    
    /// Get all registered method names.
    /// - Returns: Array of registered method names.
    public func registeredMethods() -> [String] {
        return queue.sync { Array(methodHandlers.keys) }
    }
}
