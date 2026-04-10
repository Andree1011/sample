import XCTest
@testable import MiniAppSDK

final class IoTServiceTests: XCTestCase {
    
    var iotService: IoTService!
    
    override func setUp() {
        super.setUp()
        iotService = IoTService()
    }
    
    override func tearDown() {
        iotService.stopScanning()
        iotService = nil
        super.tearDown()
    }
    
    func testIoTServiceInitialization() {
        XCTAssertNotNil(iotService)
    }
    
    func testGetDiscoveredDevicesReturnsEmpty() {
        let devices = iotService.getDiscoveredDevices()
        // Initially no devices should be discovered
        XCTAssertNotNil(devices)
    }
    
    func testDeviceInitialization() {
        let device = Device(
            id: "device-1",
            name: "Test Device",
            type: .sensor
        )
        
        XCTAssertEqual(device.id, "device-1")
        XCTAssertEqual(device.name, "Test Device")
        XCTAssertEqual(device.type, .sensor)
        XCTAssertFalse(device.isConnected)
    }
    
    func testDeviceConnectionState() {
        var device = Device(
            id: "device-1",
            name: "Test Device",
            type: .wearable,
            connectionState: .connected
        )
        XCTAssertTrue(device.isConnected)
        
        device.connectionState = .disconnected
        XCTAssertFalse(device.isConnected)
    }
    
    func testConnectToNonexistentDeviceFails() {
        let expectation = XCTestExpectation(description: "Connect fails for unknown device")
        
        iotService.connect(to: "nonexistent-device-id") { result in
            switch result {
            case .success:
                XCTFail("Expected failure for nonexistent device")
            case .failure(let error):
                if case MiniAppError.deviceNotFound(_) = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected deviceNotFound error, got: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testStopScanningDoesNotCrash() {
        XCTAssertNoThrow(iotService.stopScanning())
    }
    
    func testDisconnectFromNonexistentDeviceDoesNotCrash() {
        XCTAssertNoThrow(iotService.disconnect(from: "nonexistent-device"))
    }
    
    func testSendDataToUnconnectedDeviceFails() {
        let expectation = XCTestExpectation(description: "Send data fails")
        
        iotService.sendData(Data([1, 2, 3]), to: "unconnected-device") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure:
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}
