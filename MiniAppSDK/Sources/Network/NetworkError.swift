import Foundation

/// Custom error types for network operations.
public enum NetworkError: Error, LocalizedError {
    
    /// No internet connection
    case noConnection
    
    /// Request timed out
    case timeout
    
    /// Invalid URL
    case invalidURL(String)
    
    /// Server returned an error response
    case serverError(statusCode: Int, message: String)
    
    /// Failed to decode response
    case decodingFailed(String)
    
    /// Request was cancelled
    case cancelled
    
    /// Certificate pinning failed
    case certificatePinningFailed
    
    /// Authentication required
    case authenticationRequired
    
    /// Too many requests (rate limited)
    case rateLimited
    
    /// Unknown network error
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available."
        case .timeout:
            return "The request timed out."
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        case .decodingFailed(let message):
            return "Failed to decode response: \(message)"
        case .cancelled:
            return "The request was cancelled."
        case .certificatePinningFailed:
            return "Certificate validation failed."
        case .authenticationRequired:
            return "Authentication is required for this request."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
