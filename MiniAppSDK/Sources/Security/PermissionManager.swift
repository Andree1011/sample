import Foundation
import AVFoundation
import CoreLocation
import Contacts
import EventKit
import Photos
import CoreBluetooth
import CoreMotion
import UserNotifications

/// Manages device permissions for the Mini App SDK.
/// Handles requesting, checking, and managing permissions for device features.
public class PermissionManager: NSObject {
    
    // MARK: - Properties
    
    private let locationManager = CLLocationManager()
    private let queue = DispatchQueue(label: "com.miniapp.sdk.permissions", attributes: .concurrent)
    private var locationCompletion: ((PermissionStatus) -> Void)?
    
    // MARK: - Initializer
    
    public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Get the current status of a permission.
    /// - Parameter permission: The permission to check.
    /// - Returns: The current `PermissionStatus`.
    public func status(for permission: Permission) -> PermissionStatus {
        switch permission {
        case .camera:
            return mapAVAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return mapAVAuthorizationStatus(AVCaptureDevice.authorizationStatus(for: .audio))
        case .location, .locationAlways:
            return mapCLAuthorizationStatus(CLLocationManager.authorizationStatus())
        case .contacts:
            return mapCNAuthorizationStatus(CNContactStore.authorizationStatus(for: .contacts))
        case .calendar:
            return mapEKAuthorizationStatus(EKEventStore.authorizationStatus(for: .event))
        case .photoLibrary:
            if #available(iOS 14.0, *) {
                return mapPHAuthorizationStatus(PHPhotoLibrary.authorizationStatus(for: .readWrite))
            } else {
                return mapPHAuthorizationStatus(PHPhotoLibrary.authorizationStatus())
            }
        case .notifications:
            return .notDetermined // Async check required
        case .bluetooth:
            if #available(iOS 13.1, *) {
                return mapCBManagerAuthorization(CBCentralManager.authorization)
            }
            return .notDetermined
        case .motionActivity:
            return mapCMAuthorizationStatus(CMMotionActivityManager.authorizationStatus())
        }
    }
    
    /// Request a permission from the user.
    /// - Parameters:
    ///   - permission: The permission to request.
    ///   - completion: Callback with the resulting `PermissionStatus`.
    public func request(permission: Permission, completion: @escaping (PermissionStatus) -> Void) {
        switch permission {
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted ? .authorized : .denied)
            }
        case .microphone:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted ? .authorized : .denied)
            }
        case .location:
            queue.async(flags: .barrier) { [weak self] in
                self?.locationCompletion = completion
            }
            locationManager.requestWhenInUseAuthorization()
        case .locationAlways:
            queue.async(flags: .barrier) { [weak self] in
                self?.locationCompletion = completion
            }
            locationManager.requestAlwaysAuthorization()
        case .contacts:
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                completion(granted ? .authorized : .denied)
            }
        case .calendar:
            EKEventStore().requestAccess(to: .event) { granted, _ in
                completion(granted ? .authorized : .denied)
            }
        case .photoLibrary:
            if #available(iOS 14.0, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    completion(self.mapPHAuthorizationStatus(status))
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    completion(self.mapPHAuthorizationStatus(status))
                }
            }
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            ) { granted, _ in
                completion(granted ? .authorized : .denied)
            }
        case .bluetooth:
            // Bluetooth permission is requested when CBCentralManager is initialized
            completion(status(for: .bluetooth))
        case .motionActivity:
            let manager = CMMotionActivityManager()
            let now = Date()
            manager.queryActivityStarting(from: now, to: now, to: .main) { _, error in
                if let error = error as NSError?, error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                    completion(.denied)
                } else {
                    completion(.authorized)
                }
            }
        }
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapAVAuthorizationStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    private func mapCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    private func mapCNAuthorizationStatus(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    private func mapEKAuthorizationStatus(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    private func mapPHAuthorizationStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .limited: return .limited
        @unknown default: return .notDetermined
        }
    }
    
    @available(iOS 13.1, *)
    private func mapCBManagerAuthorization(_ authorization: CBManagerAuthorization) -> PermissionStatus {
        switch authorization {
        case .allowedAlways: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
    
    private func mapCMAuthorizationStatus(_ status: CMAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        @unknown default: return .notDetermined
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let permissionStatus = mapCLAuthorizationStatus(status)
        queue.sync {
            locationCompletion?(permissionStatus)
        }
        queue.async(flags: .barrier) { [weak self] in
            self?.locationCompletion = nil
        }
    }
}
