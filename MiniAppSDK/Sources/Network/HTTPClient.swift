import Foundation

/// Low-level HTTP client for making network requests.
/// Wraps URLSession with interceptor support.
public class HTTPClient: NSObject {
    
    // MARK: - Properties
    
    private var session: URLSession
    private var interceptors: [RequestInterceptorProtocol] = []
    private let pinnedPublicKeyHashes: [String]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.httpclient")
    
    // MARK: - Initializer
    
    public init(
        configuration: URLSessionConfiguration = .default,
        pinnedPublicKeyHashes: [String] = []
    ) {
        self.pinnedPublicKeyHashes = pinnedPublicKeyHashes
        self.session = URLSession(configuration: configuration)
        super.init()
        // Reinitialize with delegate for certificate pinning if needed
        if !pinnedPublicKeyHashes.isEmpty {
            self.session = URLSession(
                configuration: configuration,
                delegate: self,
                delegateQueue: nil
            )
        }
    }
    
    // MARK: - Public Methods
    
    /// Add a request interceptor.
    /// - Parameter interceptor: The interceptor to add.
    public func addInterceptor(_ interceptor: RequestInterceptorProtocol) {
        queue.sync { interceptors.append(interceptor) }
    }
    
    /// Execute an HTTP request.
    /// - Parameters:
    ///   - request: The URL request to execute.
    ///   - completion: Callback with data, response, and error.
    public func execute(
        request: URLRequest,
        completion: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        // Apply request interceptors
        var finalRequest = request
        queue.sync {
            for interceptor in interceptors {
                finalRequest = interceptor.intercept(request: finalRequest)
            }
        }
        
        let task = session.dataTask(with: finalRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Apply response interceptors
            var finalData = data
            var finalResponse = response
            var finalError = error
            
            self.queue.sync {
                for interceptor in self.interceptors {
                    let result = interceptor.intercept(response: finalResponse, data: finalData, error: finalError)
                    finalResponse = result.0
                    finalData = result.1
                    finalError = result.2
                }
            }
            
            completion(finalData, finalResponse, finalError)
        }
        
        task.resume()
    }
    
    /// Cancel all pending requests.
    public func cancelAllRequests() {
        session.invalidateAndCancel()
    }
}

// MARK: - URLSessionDelegate (Certificate Pinning)

extension HTTPClient: URLSessionDelegate {
    
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if pinnedPublicKeyHashes.isEmpty {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Validate certificate against pinned hashes
        let certCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certCount {
            if let cert = SecTrustGetCertificateAtIndex(serverTrust, i) {
                let certData = SecCertificateCopyData(cert) as Data
                let certHash = certData.sha256Hash()
                if pinnedPublicKeyHashes.contains(certHash) {
                    completionHandler(.useCredential, URLCredential(trust: serverTrust))
                    return
                }
            }
        }
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// MARK: - Data Extension for SHA256

private extension Data {
    func sha256Hash() -> String {
        // Simple base64 representation for demonstration
        // In production, use CommonCrypto or CryptoKit for actual SHA256
        return self.base64EncodedString()
    }
}
