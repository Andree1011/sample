import Foundation

/// Service for managing IoT device integration and communication.
public class IoTService {
    
    // MARK: - Properties
    
    private let deviceManager: DeviceManager
    private let queue = DispatchQueue(label: "com.miniapp.sdk.iot", attributes: .concurrent)
    
    /// Callback for device discovery
    public var onDeviceDiscovered: ((Device) -> Void)? {
        didSet {
            deviceManager.onDeviceDiscovered = onDeviceDiscovered
        }
    }
    
    /// Callback for device connection changes
    public var onDeviceConnectionChanged: ((String, Device.ConnectionState) -> Void)? {
        didSet {
            deviceManager.onDeviceConnectionChanged = onDeviceConnectionChanged
        }
    }
    
    /// Callback for data received from a device
    public var onDataReceived: ((String, [String: Any]) -> Void)? {
        didSet {
            deviceManager.onDataReceived = onDataReceived
        }
    }
    
    // MARK: - Initializer
    
    public init() {
        self.deviceManager = DeviceManager()
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for nearby IoT devices.
    /// - Parameters:
    ///   - serviceUUIDs: Optional service UUIDs to filter by.
    ///   - completion: Callback indicating success or failure.
    public func startScanning(
        serviceUUIDs: [String]? = nil,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        do {
            try deviceManager.startScanning(serviceUUIDs: serviceUUIDs)
            completion(.success(()))
        } catch let error as MiniAppError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknown(error.localizedDescription)))
        }
    }
    
    /// Stop scanning for IoT devices.
    public func stopScanning() {
        deviceManager.stopScanning()
    }
    
    /// Connect to a specific IoT device.
    /// - Parameters:
    ///   - deviceId: The device identifier.
    ///   - completion: Callback indicating success or failure.
    public func connect(
        to deviceId: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        deviceManager.connect(deviceId: deviceId, completion: completion)
    }
    
    /// Disconnect from a specific IoT device.
    /// - Parameter deviceId: The device identifier.
    public func disconnect(from deviceId: String) {
        deviceManager.disconnect(deviceId: deviceId)
    }
    
    /// Send data to a connected IoT device.
    /// - Parameters:
    ///   - data: The data to send.
    ///   - deviceId: The device identifier.
    ///   - completion: Callback indicating success or failure.
    public func sendData(
        _ data: Data,
        to deviceId: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        do {
            try deviceManager.send(data: data, to: deviceId)
            completion(.success(()))
        } catch let error as MiniAppError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknown(error.localizedDescription)))
        }
    }
    
    /// Get all discovered devices.
    /// - Returns: Array of discovered `Device` objects.
    public func getDiscoveredDevices() -> [Device] {
        return deviceManager.getDiscoveredDevices()
    }
    
    /// Check if Bluetooth is available on the device.
    /// - Returns: `true` if Bluetooth is available and powered on.
    public var isBluetoothAvailable: Bool {
        return deviceManager.isBluetoothAvailable
    }
}
