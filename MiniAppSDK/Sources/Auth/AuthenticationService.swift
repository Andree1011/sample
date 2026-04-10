import Foundation

/// Handles user authentication, session management, and token lifecycle.
public class AuthenticationService {
    
    // MARK: - Properties
    
    private let tokenManager: TokenManager
    private let keychainManager: KeychainManager
    private var currentUser: User?
    private let queue = DispatchQueue(label: "com.miniapp.sdk.auth", attributes: .concurrent)
    
    /// Whether a user is currently authenticated
    public var isAuthenticated: Bool {
        return queue.sync {
            guard let user = currentUser else { return false }
            return !user.isExpired
        }
    }
    
    // MARK: - Initializer
    
    public init() {
        self.tokenManager = TokenManager()
        self.keychainManager = KeychainManager()
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticate a user with credentials.
    /// - Parameters:
    ///   - username: The username or email.
    ///   - password: The user's password.
    ///   - completion: Callback with the authenticated user or an error.
    public func signIn(
        username: String,
        password: String,
        completion: @escaping (Result<User, MiniAppError>) -> Void
    ) {
        guard !username.isEmpty, !password.isEmpty else {
            completion(.failure(.invalidCredentials))
            return
        }
        
        // In production, this would make an API call to authenticate
        // Here we simulate a successful authentication
        let user = User(
            userId: UUID().uuidString,
            username: username,
            email: username.contains("@") ? username : "\(username)@example.com",
            accessToken: generateToken(),
            refreshToken: generateToken(),
            tokenExpiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
        
        queue.async(flags: .barrier) { [weak self] in
            self?.currentUser = user
        }
        
        // Save credentials securely
        do {
            try keychainManager.save(
                data: user.accessToken.data(using: .utf8)!,
                forKey: "access_token"
            )
            try keychainManager.save(
                data: user.refreshToken.data(using: .utf8)!,
                forKey: "refresh_token"
            )
        } catch {
            // Credentials save failure is non-fatal
        }
        
        completion(.success(user))
    }
    
    /// Sign out the current user.
    public func signOut() {
        queue.async(flags: .barrier) { [weak self] in
            self?.currentUser = nil
        }
        
        try? keychainManager.delete(forKey: "access_token")
        try? keychainManager.delete(forKey: "refresh_token")
        tokenManager.clearTokens()
    }
    
    /// Get the current authenticated user.
    /// - Returns: The current `User`, or nil if not authenticated.
    public func getCurrentUser() -> User? {
        return queue.sync { currentUser }
    }
    
    /// Refresh the authentication token.
    /// - Parameter completion: Callback indicating success or failure.
    public func refreshToken(completion: @escaping (Result<String, MiniAppError>) -> Void) {
        queue.sync {
            guard let user = currentUser else {
                completion(.failure(.notAuthenticated))
                return
            }
            
            tokenManager.refreshToken(currentToken: user.refreshToken) { [weak self] result in
                switch result {
                case .success(let newToken):
                    self?.queue.async(flags: .barrier) {
                        self?.currentUser = User(
                            userId: user.userId,
                            username: user.username,
                            email: user.email,
                            accessToken: newToken,
                            refreshToken: user.refreshToken,
                            tokenExpiresAt: Date().addingTimeInterval(3600)
                        )
                    }
                    completion(.success(newToken))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Get the current access token.
    /// - Returns: The access token string, or nil if not authenticated.
    /// - Throws: `MiniAppError` if token retrieval fails.
    public func getAccessToken() throws -> String {
        guard let user = queue.sync(execute: { currentUser }) else {
            throw MiniAppError.notAuthenticated
        }
        
        if user.isExpired {
            throw MiniAppError.tokenExpired
        }
        
        return user.accessToken
    }
    
    // MARK: - Private Methods
    
    private func generateToken() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
