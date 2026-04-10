import Foundation

/// Manages the lifecycle events of mini apps.
/// Provides hooks for app load, initialize, mount, unmount, and unload events.
public class AppLifecycleManager {
    
    // MARK: - Types
    
    /// Lifecycle states for a mini app
    public enum LifecycleState {
        case idle
        case loading
        case loaded
        case initializing
        case initialized
        case mounted
        case unmounted
        case unloaded
        case error(MiniAppError)
    }
    
    // MARK: - Properties
    
    private var appStates: [String: LifecycleState] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.lifecycle", attributes: .concurrent)
    
    /// Lifecycle event callbacks
    public var onAppLoadedCallback: ((AppManifest) -> Void)?
    public var onAppInitializedCallback: ((AppManifest) -> Void)?
    public var onAppMountedCallback: ((AppManifest) -> Void)?
    public var onAppUnmountedCallback: ((AppManifest) -> Void)?
    public var onAppUnloadedCallback: ((AppManifest) -> Void)?
    public var onStateChangedCallback: ((String, LifecycleState) -> Void)?
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Lifecycle Methods
    
    /// Called when an app has been loaded.
    public func onAppLoaded(manifest: AppManifest) {
        updateState(for: manifest.appId, state: .loaded)
        onAppLoadedCallback?(manifest)
    }
    
    /// Called when an app has been initialized.
    public func onAppInitialized(manifest: AppManifest) {
        updateState(for: manifest.appId, state: .initialized)
        onAppInitializedCallback?(manifest)
    }
    
    /// Called when an app has been mounted for display.
    public func onAppMounted(manifest: AppManifest) {
        updateState(for: manifest.appId, state: .mounted)
        onAppMountedCallback?(manifest)
    }
    
    /// Called when an app has been unmounted from display.
    public func onAppUnmounted(manifest: AppManifest) {
        updateState(for: manifest.appId, state: .unmounted)
        onAppUnmountedCallback?(manifest)
    }
    
    /// Called when an app has been fully unloaded.
    public func onAppUnloaded(manifest: AppManifest) {
        updateState(for: manifest.appId, state: .unloaded)
        onAppUnloadedCallback?(manifest)
        queue.async(flags: .barrier) { [weak self] in
            self?.appStates.removeValue(forKey: manifest.appId)
        }
    }
    
    // MARK: - State Management
    
    /// Get the current lifecycle state for a mini app.
    /// - Parameter appId: The identifier of the mini app.
    /// - Returns: The current `LifecycleState`, or nil if not tracked.
    public func getState(for appId: String) -> LifecycleState? {
        return queue.sync { appStates[appId] }
    }
    
    private func updateState(for appId: String, state: LifecycleState) {
        queue.async(flags: .barrier) { [weak self] in
            self?.appStates[appId] = state
        }
        onStateChangedCallback?(appId, state)
    }
}
