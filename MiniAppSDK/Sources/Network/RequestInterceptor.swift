import Foundation

/// Protocol for request/response interceptors.
public protocol RequestInterceptorProtocol {
    /// Intercept and potentially modify a request before it is sent.
    func intercept(request: URLRequest) -> URLRequest
    
    /// Process a response received from the server.
    func intercept(response: URLResponse?, data: Data?, error: Error?) -> (URLResponse?, Data?, Error?)
}

/// Default interceptor that adds authentication headers to requests.
public class AuthRequestInterceptor: RequestInterceptorProtocol {
    
    // MARK: - Properties
    
    private weak var authService: AuthenticationService?
    
    // MARK: - Initializer
    
    public init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    // MARK: - RequestInterceptorProtocol
    
    public func intercept(request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        
        if let token = try? authService?.getAccessToken() {
            modifiedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return modifiedRequest
    }
    
    public func intercept(response: URLResponse?, data: Data?, error: Error?) -> (URLResponse?, Data?, Error?) {
        return (response, data, error)
    }
}

/// Interceptor that logs requests and responses.
public class LoggingInterceptor: RequestInterceptorProtocol {
    
    // MARK: - Properties
    
    private let enabled: Bool
    
    // MARK: - Initializer
    
    public init(enabled: Bool = false) {
        self.enabled = enabled
    }
    
    // MARK: - RequestInterceptorProtocol
    
    public func intercept(request: URLRequest) -> URLRequest {
        if enabled {
            print("[NetworkService] → \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
            if let headers = request.allHTTPHeaderFields {
                print("[NetworkService] Headers: \(headers)")
            }
        }
        return request
    }
    
    public func intercept(response: URLResponse?, data: Data?, error: Error?) -> (URLResponse?, Data?, Error?) {
        if enabled {
            if let httpResponse = response as? HTTPURLResponse {
                print("[NetworkService] ← \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")")
            }
            if let error = error {
                print("[NetworkService] Error: \(error.localizedDescription)")
            }
        }
        return (response, data, error)
    }
}

/// Interceptor that adds common headers to all requests.
public class CommonHeadersInterceptor: RequestInterceptorProtocol {
    
    // MARK: - Properties
    
    private let headers: [String: String]
    
    // MARK: - Initializer
    
    public init(headers: [String: String]) {
        self.headers = headers
    }
    
    // MARK: - RequestInterceptorProtocol
    
    public func intercept(request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        headers.forEach { key, value in
            modifiedRequest.setValue(value, forHTTPHeaderField: key)
        }
        return modifiedRequest
    }
    
    public func intercept(response: URLResponse?, data: Data?, error: Error?) -> (URLResponse?, Data?, Error?) {
        return (response, data, error)
    }
}
