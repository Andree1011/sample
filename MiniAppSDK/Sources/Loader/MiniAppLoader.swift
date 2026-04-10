import Foundation

/// Manages the loading and lifecycle of mini apps.
/// Supports both web view and native module loading.
public class MiniAppLoader {
    
    // MARK: - Properties
    
    private let lifecycleManager: AppLifecycleManager
    private var loadedApps: [String: AppManifest] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.loader", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {
        self.lifecycleManager = AppLifecycleManager()
    }
    
    // MARK: - Public Methods
    
    /// Load a mini app by its identifier.
    /// - Parameters:
    ///   - appId: The identifier of the mini app to load.
    ///   - completion: Callback with the loaded manifest or an error.
    public func loadApp(appId: String, completion: @escaping (Result<AppManifest, MiniAppError>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if already loaded
            if let manifest = self.queue.sync(execute: { self.loadedApps[appId] }) {
                completion(.success(manifest))
                return
            }
            
            // Simulate app loading - in production, this would fetch from server or cache
            guard !appId.isEmpty else {
                completion(.failure(.appNotFound(appId)))
                return
            }
            
            // Create manifest for the app
            let manifest = AppManifest(
                appId: appId,
                version: "1.0.0",
                name: appId,
                entryPoint: "index.html",
                permissions: [],
                minSDKVersion: "1.0.0"
            )
            
            // Store the loaded app
            self.queue.async(flags: .barrier) {
                self.loadedApps[appId] = manifest
            }
            
            // Notify lifecycle manager
            self.lifecycleManager.onAppLoaded(manifest: manifest)
            
            completion(.success(manifest))
        }
    }
    
    /// Initialize a loaded mini app.
    /// - Parameters:
    ///   - appId: The identifier of the mini app.
    ///   - completion: Callback indicating success or failure.
    public func initializeApp(appId: String, completion: @escaping (Result<Void, MiniAppError>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard let manifest = self.queue.sync(execute: { self.loadedApps[appId] }) else {
                completion(.failure(.appNotFound(appId)))
                return
            }
            
            self.lifecycleManager.onAppInitialized(manifest: manifest)
            completion(.success(()))
        }
    }
    
    /// Mount a mini app for display.
    /// - Parameters:
    ///   - appId: The identifier of the mini app.
    ///   - completion: Callback indicating success or failure.
    public func mountApp(appId: String, completion: @escaping (Result<Void, MiniAppError>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard let manifest = self.queue.sync(execute: { self.loadedApps[appId] }) else {
                completion(.failure(.appNotFound(appId)))
                return
            }
            
            self.lifecycleManager.onAppMounted(manifest: manifest)
            completion(.success(()))
        }
    }
    
    /// Unmount a mini app from display.
    /// - Parameters:
    ///   - appId: The identifier of the mini app.
    ///   - completion: Callback indicating success or failure.
    public func unmountApp(appId: String, completion: @escaping (Result<Void, MiniAppError>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            guard let manifest = self.queue.sync(execute: { self.loadedApps[appId] }) else {
                completion(.failure(.appNotFound(appId)))
                return
            }
            
            self.lifecycleManager.onAppUnmounted(manifest: manifest)
            completion(.success(()))
        }
    }
    
    /// Unload a mini app completely.
    /// - Parameters:
    ///   - appId: The identifier of the mini app.
    public func unloadApp(appId: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let manifest = self.loadedApps[appId] {
                self.lifecycleManager.onAppUnloaded(manifest: manifest)
                self.loadedApps.removeValue(forKey: appId)
            }
        }
    }
    
    /// Get all loaded app manifests.
    /// - Returns: An array of loaded `AppManifest` objects.
    public func getLoadedApps() -> [AppManifest] {
        return queue.sync { Array(loadedApps.values) }
    }
    
    /// Check if a specific app is loaded.
    /// - Parameter appId: The identifier of the mini app.
    /// - Returns: `true` if loaded, `false` otherwise.
    public func isAppLoaded(appId: String) -> Bool {
        return queue.sync { loadedApps[appId] != nil }
    }
}
