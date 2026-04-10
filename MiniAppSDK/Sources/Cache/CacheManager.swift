import Foundation

/// Manages caching of mini app bundles and resources.
/// Uses an LRU (Least Recently Used) eviction policy.
public class CacheManager {
    
    // MARK: - Properties
    
    private let storageManager: StorageManager
    private let cachePolicy: CachePolicy
    private var memoryCache: [String: CacheEntry] = [:]
    private var accessOrder: [String] = []
    private let queue = DispatchQueue(label: "com.miniapp.sdk.cache", attributes: .concurrent)
    
    /// Maximum number of items to keep in memory cache
    public var maxMemoryCacheSize: Int {
        return cachePolicy.maxMemoryCacheSize
    }
    
    // MARK: - Types
    
    struct CacheEntry {
        let key: String
        let data: Data
        let version: String
        let expiresAt: Date?
        let createdAt: Date
        
        var isExpired: Bool {
            guard let expiresAt = expiresAt else { return false }
            return Date() > expiresAt
        }
    }
    
    // MARK: - Initializer
    
    public init(cachePolicy: CachePolicy = CachePolicy()) {
        self.cachePolicy = cachePolicy
        self.storageManager = StorageManager()
    }
    
    // MARK: - Public Methods
    
    /// Store data in the cache.
    /// - Parameters:
    ///   - data: The data to cache.
    ///   - key: The cache key.
    ///   - version: The version of the cached data.
    ///   - ttl: Time-to-live in seconds (optional).
    /// - Throws: `MiniAppError` if caching fails.
    public func store(data: Data, forKey key: String, version: String, ttl: TimeInterval? = nil) throws {
        let expiresAt = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(
            key: key,
            data: data,
            version: version,
            expiresAt: expiresAt,
            createdAt: Date()
        )
        
        try queue.sync(flags: .barrier) {
            // Evict if at capacity
            if self.memoryCache.count >= self.cachePolicy.maxMemoryCacheSize && self.memoryCache[key] == nil {
                self.evictLRU()
            }
            
            self.memoryCache[key] = entry
            
            // Update LRU access order
            self.accessOrder.removeAll { $0 == key }
            self.accessOrder.append(key)
            
            // Persist to disk
            try self.storageManager.write(data: data, forKey: key)
        }
    }
    
    /// Retrieve data from cache.
    /// - Parameters:
    ///   - key: The cache key.
    ///   - version: Expected version (optional, for version validation).
    /// - Returns: The cached data.
    /// - Throws: `MiniAppError.cacheMiss` if not found or expired.
    public func retrieve(forKey key: String, version: String? = nil) throws -> Data {
        return try queue.sync {
            // Check memory cache first
            if let entry = self.memoryCache[key] {
                if entry.isExpired {
                    self.removeFromMemoryCache(key: key)
                    throw MiniAppError.cacheMiss
                }
                
                if let version = version, entry.version != version {
                    throw MiniAppError.versionMismatch("Cached version \(entry.version) does not match requested version \(version)")
                }
                
                // Update LRU order
                self.accessOrder.removeAll { $0 == key }
                self.accessOrder.append(key)
                
                return entry.data
            }
            
            // Fall back to disk cache
            guard let data = try? self.storageManager.read(forKey: key) else {
                throw MiniAppError.cacheMiss
            }
            
            return data
        }
    }
    
    /// Remove a specific item from cache.
    /// - Parameter key: The cache key to remove.
    public func remove(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.removeFromMemoryCache(key: key)
            try? self?.storageManager.delete(forKey: key)
        }
    }
    
    /// Clear all items from cache.
    public func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.memoryCache.removeAll()
            self?.accessOrder.removeAll()
            self?.storageManager.clearAll()
        }
    }
    
    /// Check if an item exists in cache.
    /// - Parameter key: The cache key to check.
    /// - Returns: `true` if item exists and is not expired.
    public func contains(key: String) -> Bool {
        return queue.sync {
            if let entry = memoryCache[key] {
                return !entry.isExpired
            }
            return (try? storageManager.read(forKey: key)) != nil
        }
    }
    
    /// Get the total size of cached data on disk.
    /// - Returns: Total size in bytes.
    public func totalCacheSize() -> Int64 {
        return storageManager.totalSize()
    }
    
    // MARK: - Private Methods
    
    private func evictLRU() {
        guard let lruKey = accessOrder.first else { return }
        removeFromMemoryCache(key: lruKey)
    }
    
    private func removeFromMemoryCache(key: String) {
        memoryCache.removeValue(forKey: key)
        accessOrder.removeAll { $0 == key }
    }
}
