import Foundation

/// High-level network service for making HTTP requests.
/// Provides type-safe request/response handling with automatic retry logic.
public class NetworkService {
    
    // MARK: - Properties
    
    private let httpClient: HTTPClient
    private let baseURL: URL?
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    // MARK: - Initializer
    
    public init(
        baseURL: URL? = nil,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        pinnedPublicKeyHashes: [String] = []
    ) {
        self.baseURL = baseURL
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        self.httpClient = HTTPClient(
            configuration: configuration,
            pinnedPublicKeyHashes: pinnedPublicKeyHashes
        )
        
        // Add default interceptors
        httpClient.addInterceptor(LoggingInterceptor(enabled: false))
        httpClient.addInterceptor(CommonHeadersInterceptor(headers: [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-SDK-Version": "1.0.0"
        ]))
    }
    
    // MARK: - Public Methods
    
    /// Perform a GET request.
    /// - Parameters:
    ///   - path: The request path (appended to baseURL if set).
    ///   - parameters: Query parameters (optional).
    ///   - headers: Additional headers (optional).
    ///   - completion: Callback with response data or error.
    public func get(
        path: String,
        parameters: [String: String]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let request = buildRequest(
            path: path,
            method: "GET",
            parameters: parameters,
            headers: headers
        ) else {
            completion(.failure(.invalidURL(path)))
            return
        }
        
        execute(request: request, retries: maxRetries, completion: completion)
    }
    
    /// Perform a POST request.
    /// - Parameters:
    ///   - path: The request path.
    ///   - body: The request body (optional).
    ///   - headers: Additional headers (optional).
    ///   - completion: Callback with response data or error.
    public func post(
        path: String,
        body: Data? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let request = buildRequest(
            path: path,
            method: "POST",
            body: body,
            headers: headers
        ) else {
            completion(.failure(.invalidURL(path)))
            return
        }
        
        execute(request: request, retries: maxRetries, completion: completion)
    }
    
    /// Perform a PUT request.
    /// - Parameters:
    ///   - path: The request path.
    ///   - body: The request body (optional).
    ///   - headers: Additional headers (optional).
    ///   - completion: Callback with response data or error.
    public func put(
        path: String,
        body: Data? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let request = buildRequest(
            path: path,
            method: "PUT",
            body: body,
            headers: headers
        ) else {
            completion(.failure(.invalidURL(path)))
            return
        }
        
        execute(request: request, retries: maxRetries, completion: completion)
    }
    
    /// Perform a DELETE request.
    /// - Parameters:
    ///   - path: The request path.
    ///   - headers: Additional headers (optional).
    ///   - completion: Callback with response data or error.
    public func delete(
        path: String,
        headers: [String: String]? = nil,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let request = buildRequest(
            path: path,
            method: "DELETE",
            headers: headers
        ) else {
            completion(.failure(.invalidURL(path)))
            return
        }
        
        execute(request: request, retries: maxRetries, completion: completion)
    }
    
    /// Add an interceptor to the HTTP client.
    /// - Parameter interceptor: The interceptor to add.
    public func addInterceptor(_ interceptor: RequestInterceptorProtocol) {
        httpClient.addInterceptor(interceptor)
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(
        path: String,
        method: String,
        parameters: [String: String]? = nil,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) -> URLRequest? {
        var urlComponents: URLComponents?
        
        if let baseURL = baseURL {
            urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        } else {
            urlComponents = URLComponents(string: path)
        }
        
        if let parameters = parameters, !parameters.isEmpty {
            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func execute(
        request: URLRequest,
        retries: Int,
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        httpClient.execute(request: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                let nsError = error as NSError
                
                // Check if retryable
                if retries > 0 && self.isRetryableError(nsError) {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.retryDelay) {
                        self.execute(request: request, retries: retries - 1, completion: completion)
                    }
                    return
                }
                
                if nsError.code == NSURLErrorTimedOut {
                    completion(.failure(.timeout))
                } else if nsError.code == NSURLErrorNotConnectedToInternet {
                    completion(.failure(.noConnection))
                } else if nsError.code == NSURLErrorCancelled {
                    completion(.failure(.cancelled))
                } else {
                    completion(.failure(.unknown(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknown(NSError(domain: "NetworkService", code: -1))))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.success(data ?? Data()))
            case 401:
                completion(.failure(.authenticationRequired))
            case 429:
                completion(.failure(.rateLimited))
            default:
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
            }
        }
    }
    
    private func isRetryableError(_ error: NSError) -> Bool {
        let retryableCodes = [
            NSURLErrorTimedOut,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorCannotConnectToHost
        ]
        return retryableCodes.contains(error.code)
    }
}
