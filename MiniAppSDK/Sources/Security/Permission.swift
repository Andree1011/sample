import Foundation

/// Represents a permission type in the Mini App SDK.
public enum Permission: String, CaseIterable, Codable {
    case camera
    case microphone
    case location
    case locationAlways
    case contacts
    case calendar
    case photoLibrary
    case notifications
    case bluetooth
    case motionActivity
    
    /// Human-readable name for the permission
    public var displayName: String {
        switch self {
        case .camera: return "Camera"
        case .microphone: return "Microphone"
        case .location: return "Location (When In Use)"
        case .locationAlways: return "Location (Always)"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .photoLibrary: return "Photo Library"
        case .notifications: return "Notifications"
        case .bluetooth: return "Bluetooth"
        case .motionActivity: return "Motion & Fitness"
        }
    }
    
    /// Reason description for the permission request
    public var usageDescription: String {
        switch self {
        case .camera: return "Required to take photos and scan QR codes."
        case .microphone: return "Required for audio/video communication."
        case .location: return "Required to provide location-based services."
        case .locationAlways: return "Required to provide background location services."
        case .contacts: return "Required to access your contacts for sharing."
        case .calendar: return "Required to add and manage calendar events."
        case .photoLibrary: return "Required to access your photo library."
        case .notifications: return "Required to send you important notifications."
        case .bluetooth: return "Required to connect to Bluetooth devices."
        case .motionActivity: return "Required to track physical activity."
        }
    }
}

/// Represents the current status of a permission.
public enum PermissionStatus {
    case authorized
    case denied
    case notDetermined
    case restricted
    case limited
    
    /// Whether the permission has been granted
    public var isGranted: Bool {
        return self == .authorized || self == .limited
    }
}
