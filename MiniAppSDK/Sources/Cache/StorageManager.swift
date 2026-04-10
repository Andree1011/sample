import Foundation

/// Manages persistent storage for cached mini app data.
/// Handles file system operations for reading and writing cached bundles.
public class StorageManager {
    
    // MARK: - Properties
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    // MARK: - Initializer
    
    public init() {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("MiniAppSDK", isDirectory: true)
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Write data to disk with a given key.
    /// - Parameters:
    ///   - data: The data to persist.
    ///   - key: The storage key (used as filename).
    /// - Throws: `MiniAppError` if writing fails.
    public func write(data: Data, forKey key: String) throws {
        let filePath = fileURL(for: key)
        do {
            try data.write(to: filePath, options: .atomic)
        } catch {
            throw MiniAppError.cacheWriteFailed(error.localizedDescription)
        }
    }
    
    /// Read data from disk for a given key.
    /// - Parameter key: The storage key.
    /// - Returns: The stored data.
    /// - Throws: `MiniAppError.cacheMiss` if not found.
    public func read(forKey key: String) throws -> Data {
        let filePath = fileURL(for: key)
        guard let data = try? Data(contentsOf: filePath) else {
            throw MiniAppError.cacheMiss
        }
        return data
    }
    
    /// Delete data from disk for a given key.
    /// - Parameter key: The storage key.
    /// - Throws: `MiniAppError` if deletion fails.
    public func delete(forKey key: String) throws {
        let filePath = fileURL(for: key)
        guard fileManager.fileExists(atPath: filePath.path) else { return }
        do {
            try fileManager.removeItem(at: filePath)
        } catch {
            throw MiniAppError.unknown(error.localizedDescription)
        }
    }
    
    /// Clear all stored data.
    public func clearAll() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in contents {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            // Ignore errors during clear
        }
    }
    
    /// Get the total size of all stored data.
    /// - Returns: Total size in bytes.
    public func totalSize() -> Int64 {
        var totalSize: Int64 = 0
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            for file in contents {
                let resourceValues = try? file.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues?.fileSize ?? 0)
            }
        } catch {
            // Ignore errors
        }
        return totalSize
    }
    
    // MARK: - Private Methods
    
    private func fileURL(for key: String) -> URL {
        // Sanitize key to create a valid filename
        let sanitizedKey = key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        return cacheDirectory.appendingPathComponent(sanitizedKey)
    }
    
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
