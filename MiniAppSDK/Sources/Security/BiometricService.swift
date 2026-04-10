import Foundation
import LocalAuthentication

/// Provides biometric authentication (Face ID / Touch ID) capabilities.
public class BiometricService {
    
    // MARK: - Types
    
    /// Available biometric types
    public enum BiometricType {
        case faceID
        case touchID
        case none
    }
    
    // MARK: - Properties
    
    private let context: LAContext
    
    // MARK: - Initializer
    
    public init() {
        self.context = LAContext()
    }
    
    // MARK: - Public Methods
    
    /// Get the available biometric type on the current device.
    /// - Returns: The available `BiometricType`.
    public func availableBiometricType() -> BiometricType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            default:
                return .none
            }
        } else {
            return .touchID
        }
    }
    
    /// Check if biometric authentication is available.
    /// - Returns: `true` if biometric authentication is available.
    public func isBiometricAvailable() -> Bool {
        return availableBiometricType() != .none
    }
    
    /// Authenticate the user using biometric authentication.
    /// - Parameters:
    ///   - reason: The reason displayed to the user for authentication.
    ///   - completion: Callback indicating success or failure.
    public func authenticate(
        reason: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        guard isBiometricAvailable() else {
            completion(.failure(.biometricNotAvailable))
            return
        }
        
        let authContext = LAContext()
        authContext.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let error = error {
                    completion(.failure(.biometricFailed(error.localizedDescription)))
                } else {
                    completion(.failure(.biometricFailed("Authentication failed")))
                }
            }
        }
    }
    
    /// Authenticate using device passcode as fallback.
    /// - Parameters:
    ///   - reason: The reason displayed to the user.
    ///   - completion: Callback indicating success or failure.
    public func authenticateWithPasscode(
        reason: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        let authContext = LAContext()
        var error: NSError?
        
        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(.failure(.biometricNotAvailable))
            return
        }
        
        authContext.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let error = error {
                    completion(.failure(.biometricFailed(error.localizedDescription)))
                } else {
                    completion(.failure(.biometricFailed("Authentication failed")))
                }
            }
        }
    }
}
