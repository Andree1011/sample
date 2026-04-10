import Foundation

/// SDK Permission Layer that manages permissions at the SDK level.
/// Acts as a middle layer between mini apps and the device permission manager.
public class SDKPermissionLayer {
    
    // MARK: - Properties
    
    private let permissionManager: PermissionManager
    private var grantedPermissions: Set<Permission> = []
    private var deniedPermissions: Set<Permission> = []
    private var appPermissions: [String: Set<Permission>] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.sdkpermission", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init(permissionManager: PermissionManager = PermissionManager()) {
        self.permissionManager = permissionManager
    }
    
    // MARK: - Public Methods
    
    /// Grant a permission to a specific mini app.
    /// - Parameters:
    ///   - permission: The permission to grant.
    ///   - appId: The mini app identifier.
    ///   - completion: Callback with the resulting status.
    public func grantPermission(
        _ permission: Permission,
        to appId: String,
        completion: @escaping (Result<PermissionStatus, MiniAppError>) -> Void
    ) {
        let currentStatus = permissionManager.status(for: permission)
        
        switch currentStatus {
        case .authorized, .limited:
            recordPermission(permission, for: appId, granted: true)
            completion(.success(.authorized))
            
        case .denied, .restricted:
            completion(.failure(.permissionDenied(permission.rawValue)))
            
        case .notDetermined:
            permissionManager.request(permission: permission) { [weak self] status in
                switch status {
                case .authorized, .limited:
                    self?.recordPermission(permission, for: appId, granted: true)
                    completion(.success(status))
                case .denied, .restricted:
                    self?.recordPermission(permission, for: appId, granted: false)
                    completion(.failure(.permissionDenied(permission.rawValue)))
                case .notDetermined:
                    completion(.failure(.permissionNotDetermined(permission.rawValue)))
                }
            }
        }
    }
    
    /// Revoke a permission from a mini app.
    /// - Parameters:
    ///   - permission: The permission to revoke.
    ///   - appId: The mini app identifier.
    public func revokePermission(_ permission: Permission, from appId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.appPermissions[appId]?.remove(permission)
        }
    }
    
    /// Check if a mini app has a specific permission.
    /// - Parameters:
    ///   - permission: The permission to check.
    ///   - appId: The mini app identifier.
    /// - Returns: `true` if the app has been granted the permission.
    public func hasPermission(_ permission: Permission, for appId: String) -> Bool {
        return queue.sync {
            appPermissions[appId]?.contains(permission) ?? false
        }
    }
    
    /// Get all permissions for a specific mini app.
    /// - Parameter appId: The mini app identifier.
    /// - Returns: Set of granted permissions.
    public func getPermissions(for appId: String) -> Set<Permission> {
        return queue.sync { appPermissions[appId] ?? [] }
    }
    
    /// Check and request multiple permissions for a mini app.
    /// - Parameters:
    ///   - permissions: The permissions to request.
    ///   - appId: The mini app identifier.
    ///   - completion: Callback with a dictionary of permission statuses.
    public func requestPermissions(
        _ permissions: [Permission],
        for appId: String,
        completion: @escaping ([Permission: PermissionStatus]) -> Void
    ) {
        var results: [Permission: PermissionStatus] = [:]
        let group = DispatchGroup()
        let resultQueue = DispatchQueue(label: "com.miniapp.sdk.sdkpermission.results")
        
        for permission in permissions {
            group.enter()
            grantPermission(permission, to: appId) { result in
                resultQueue.async {
                    switch result {
                    case .success(let status):
                        results[permission] = status
                    case .failure:
                        results[permission] = .denied
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
    
    // MARK: - Private Methods
    
    private func recordPermission(_ permission: Permission, for appId: String, granted: Bool) {
        queue.async(flags: .barrier) { [weak self] in
            if self?.appPermissions[appId] == nil {
                self?.appPermissions[appId] = []
            }
            
            if granted {
                self?.appPermissions[appId]?.insert(permission)
                self?.grantedPermissions.insert(permission)
            } else {
                self?.appPermissions[appId]?.remove(permission)
                self?.deniedPermissions.insert(permission)
            }
        }
    }
}
