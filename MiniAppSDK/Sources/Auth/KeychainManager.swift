import Foundation
import Security

/// Provides secure storage and retrieval of sensitive data using iOS Keychain.
public class KeychainManager {
    
    // MARK: - Properties
    
    private let serviceName: String
    
    // MARK: - Initializer
    
    public init(serviceName: String = "com.miniapp.sdk") {
        self.serviceName = serviceName
    }
    
    // MARK: - Public Methods
    
    /// Save data to the Keychain.
    /// - Parameters:
    ///   - data: The data to store.
    ///   - key: The Keychain key (account name).
    /// - Throws: `MiniAppError` if saving fails.
    public func save(data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw MiniAppError.cacheWriteFailed("Keychain save failed with status: \(status)")
        }
    }
    
    /// Retrieve data from the Keychain.
    /// - Parameter key: The Keychain key (account name).
    /// - Returns: The stored data.
    /// - Throws: `MiniAppError.cacheMiss` if not found.
    public func retrieve(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw MiniAppError.cacheMiss
        }
        
        return data
    }
    
    /// Delete data from the Keychain.
    /// - Parameter key: The Keychain key (account name).
    /// - Throws: `MiniAppError` if deletion fails.
    public func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw MiniAppError.unknown("Keychain delete failed with status: \(status)")
        }
    }
    
    /// Save a string value to the Keychain.
    /// - Parameters:
    ///   - value: The string to store.
    ///   - key: The Keychain key.
    /// - Throws: `MiniAppError` if saving fails.
    public func saveString(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw MiniAppError.unknown("Failed to convert string to data")
        }
        try save(data: data, forKey: key)
    }
    
    /// Retrieve a string value from the Keychain.
    /// - Parameter key: The Keychain key.
    /// - Returns: The stored string.
    /// - Throws: `MiniAppError` if retrieval fails.
    public func retrieveString(forKey key: String) throws -> String {
        let data = try retrieve(forKey: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw MiniAppError.unknown("Failed to convert data to string")
        }
        return string
    }
    
    /// Check if a key exists in the Keychain.
    /// - Parameter key: The Keychain key.
    /// - Returns: `true` if the key exists.
    public func exists(forKey key: String) -> Bool {
        return (try? retrieve(forKey: key)) != nil
    }
    
    /// Clear all items for this service from the Keychain.
    public func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(query as CFDictionary)
    }
}
