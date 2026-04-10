import Foundation

/// Configuration for cache behavior including size limits and TTL settings.
public struct CachePolicy {
    
    // MARK: - Properties
    
    /// Maximum number of items to keep in memory
    public let maxMemoryCacheSize: Int
    
    /// Maximum disk cache size in bytes (default: 100MB)
    public let maxDiskCacheSize: Int64
    
    /// Default time-to-live for cached items in seconds (default: 24 hours)
    public let defaultTTL: TimeInterval
    
    /// Whether to use memory caching
    public let useMemoryCache: Bool
    
    /// Whether to use disk caching
    public let useDiskCache: Bool
    
    // MARK: - Initializer
    
    public init(
        maxMemoryCacheSize: Int = 50,
        maxDiskCacheSize: Int64 = 100 * 1024 * 1024, // 100MB
        defaultTTL: TimeInterval = 24 * 60 * 60, // 24 hours
        useMemoryCache: Bool = true,
        useDiskCache: Bool = true
    ) {
        self.maxMemoryCacheSize = maxMemoryCacheSize
        self.maxDiskCacheSize = maxDiskCacheSize
        self.defaultTTL = defaultTTL
        self.useMemoryCache = useMemoryCache
        self.useDiskCache = useDiskCache
    }
    
    // MARK: - Predefined Policies
    
    /// Aggressive caching policy for performance-critical apps
    public static var aggressive: CachePolicy {
        return CachePolicy(
            maxMemoryCacheSize: 100,
            maxDiskCacheSize: 200 * 1024 * 1024,
            defaultTTL: 7 * 24 * 60 * 60
        )
    }
    
    /// Conservative caching policy for memory-constrained devices
    public static var conservative: CachePolicy {
        return CachePolicy(
            maxMemoryCacheSize: 10,
            maxDiskCacheSize: 50 * 1024 * 1024,
            defaultTTL: 60 * 60
        )
    }
    
    /// No caching policy (for debug or fresh data requirements)
    public static var noCache: CachePolicy {
        return CachePolicy(
            maxMemoryCacheSize: 0,
            maxDiskCacheSize: 0,
            defaultTTL: 0,
            useMemoryCache: false,
            useDiskCache: false
        )
    }
}
