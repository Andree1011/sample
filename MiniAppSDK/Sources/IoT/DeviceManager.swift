import Foundation
import CoreBluetooth

/// Manages Bluetooth device discovery, connection, and communication.
public class DeviceManager: NSObject {
    
    // MARK: - Properties
    
    private var centralManager: CBCentralManager?
    private var discoveredPeripherals: [String: CBPeripheral] = [:]
    private var connectedPeripherals: [String: CBPeripheral] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.devicemanager", attributes: .concurrent)
    
    /// Callback for device discovery
    public var onDeviceDiscovered: ((Device) -> Void)?
    
    /// Callback for device connection changes
    public var onDeviceConnectionChanged: ((String, Device.ConnectionState) -> Void)?
    
    /// Callback for data received from device
    public var onDataReceived: ((String, [String: Any]) -> Void)?
    
    /// Whether Bluetooth is available and powered on
    public var isBluetoothAvailable: Bool {
        guard let manager = centralManager else { return false }
        return manager.state == .poweredOn
    }
    
    // MARK: - Initializer
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    // MARK: - Public Methods
    
    /// Start scanning for nearby Bluetooth devices.
    /// - Parameter serviceUUIDs: Optional array of service UUIDs to filter by.
    public func startScanning(serviceUUIDs: [String]? = nil) throws {
        guard isBluetoothAvailable else {
            throw MiniAppError.bluetoothNotAvailable
        }
        
        let uuids = serviceUUIDs?.compactMap { CBUUID(string: $0) }
        centralManager?.scanForPeripherals(withServices: uuids, options: nil)
    }
    
    /// Stop scanning for Bluetooth devices.
    public func stopScanning() {
        centralManager?.stopScan()
    }
    
    /// Connect to a specific device.
    /// - Parameters:
    ///   - deviceId: The device identifier.
    ///   - completion: Callback indicating success or failure.
    public func connect(deviceId: String, completion: @escaping (Result<Void, MiniAppError>) -> Void) {
        guard let peripheral = queue.sync(execute: { discoveredPeripherals[deviceId] }) else {
            completion(.failure(.deviceNotFound(deviceId)))
            return
        }
        
        centralManager?.connect(peripheral, options: nil)
        // Connection result will come via delegate
        onDeviceConnectionChanged?(deviceId, .connecting)
    }
    
    /// Disconnect from a specific device.
    /// - Parameter deviceId: The device identifier.
    public func disconnect(deviceId: String) {
        guard let peripheral = queue.sync(execute: { connectedPeripherals[deviceId] }) else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
    }
    
    /// Send data to a connected device.
    /// - Parameters:
    ///   - data: The data to send.
    ///   - deviceId: The device identifier.
    /// - Throws: `MiniAppError` if device not connected.
    public func send(data: Data, to deviceId: String) throws {
        guard queue.sync(execute: { connectedPeripherals[deviceId] }) != nil else {
            throw MiniAppError.deviceConnectionFailed("Device \(deviceId) is not connected")
        }
        
        // In production, find the appropriate characteristic and write to it
        // peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    /// Get all discovered devices.
    /// - Returns: Array of discovered `Device` objects.
    public func getDiscoveredDevices() -> [Device] {
        return queue.sync {
            discoveredPeripherals.map { id, peripheral in
                Device(
                    id: id,
                    name: peripheral.name ?? "Unknown Device",
                    type: .other,
                    bluetoothIdentifier: peripheral.identifier.uuidString,
                    connectionState: connectedPeripherals[id] != nil ? .connected : .disconnected
                )
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DeviceManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff, .unauthorized, .unsupported:
            break
        default:
            break
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let deviceId = peripheral.identifier.uuidString
        
        queue.async(flags: .barrier) { [weak self] in
            self?.discoveredPeripherals[deviceId] = peripheral
        }
        
        let device = Device(
            id: deviceId,
            name: peripheral.name ?? "Unknown Device",
            type: .other,
            bluetoothIdentifier: deviceId,
            connectionState: .disconnected,
            rssi: RSSI.intValue,
            lastSeenAt: Date()
        )
        
        onDeviceDiscovered?(device)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceId = peripheral.identifier.uuidString
        
        queue.async(flags: .barrier) { [weak self] in
            self?.connectedPeripherals[deviceId] = peripheral
        }
        
        onDeviceConnectionChanged?(deviceId, .connected)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        let deviceId = peripheral.identifier.uuidString
        
        queue.async(flags: .barrier) { [weak self] in
            self?.connectedPeripherals.removeValue(forKey: deviceId)
        }
        
        onDeviceConnectionChanged?(deviceId, .disconnected)
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let deviceId = peripheral.identifier.uuidString
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        onDeviceConnectionChanged?(deviceId, .error(errorMessage))
    }
}
