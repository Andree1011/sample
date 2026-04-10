import Foundation

/// Represents an IoT device in the Mini App SDK.
public struct Device: Identifiable {
    
    // MARK: - Types
    
    /// Device connection state
    public enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case disconnecting
        case error(String)
    }
    
    /// Device type
    public enum DeviceType: String {
        case sensor
        case actuator
        case gateway
        case wearable
        case smartHome
        case medical
        case industrial
        case other
    }
    
    // MARK: - Properties
    
    /// Unique identifier for the device
    public let id: String
    
    /// Device name
    public let name: String
    
    /// Device type
    public let type: DeviceType
    
    /// Device manufacturer
    public let manufacturer: String?
    
    /// Device model
    public let model: String?
    
    /// Bluetooth peripheral identifier (UUID)
    public let bluetoothIdentifier: String?
    
    /// Current connection state
    public var connectionState: ConnectionState
    
    /// Last known signal strength (RSSI)
    public var rssi: Int?
    
    /// Last data received from device
    public var lastData: [String: Any]?
    
    /// Timestamp of last communication
    public var lastSeenAt: Date?
    
    // MARK: - Computed Properties
    
    /// Whether the device is currently connected
    public var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }
    
    // MARK: - Initializer
    
    public init(
        id: String,
        name: String,
        type: DeviceType,
        manufacturer: String? = nil,
        model: String? = nil,
        bluetoothIdentifier: String? = nil,
        connectionState: ConnectionState = .disconnected,
        rssi: Int? = nil,
        lastData: [String: Any]? = nil,
        lastSeenAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.bluetoothIdentifier = bluetoothIdentifier
        self.connectionState = connectionState
        self.rssi = rssi
        self.lastData = lastData
        self.lastSeenAt = lastSeenAt
    }
}
