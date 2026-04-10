import XCTest
@testable import MiniAppSDK

final class PermissionTests: XCTestCase {
    
    func testAllPermissionsHaveDisplayName() {
        for permission in Permission.allCases {
            XCTAssertFalse(permission.displayName.isEmpty, "\(permission.rawValue) should have a display name")
        }
    }
    
    func testAllPermissionsHaveUsageDescription() {
        for permission in Permission.allCases {
            XCTAssertFalse(permission.usageDescription.isEmpty, "\(permission.rawValue) should have a usage description")
        }
    }
    
    func testPermissionStatusIsGranted() {
        XCTAssertTrue(PermissionStatus.authorized.isGranted)
        XCTAssertTrue(PermissionStatus.limited.isGranted)
        XCTAssertFalse(PermissionStatus.denied.isGranted)
        XCTAssertFalse(PermissionStatus.notDetermined.isGranted)
        XCTAssertFalse(PermissionStatus.restricted.isGranted)
    }
    
    func testPermissionRawValues() {
        XCTAssertEqual(Permission.camera.rawValue, "camera")
        XCTAssertEqual(Permission.microphone.rawValue, "microphone")
        XCTAssertEqual(Permission.location.rawValue, "location")
        XCTAssertEqual(Permission.contacts.rawValue, "contacts")
    }
}

final class SDKPermissionLayerTests: XCTestCase {
    
    var sdkPermissionLayer: SDKPermissionLayer!
    
    override func setUp() {
        super.setUp()
        sdkPermissionLayer = SDKPermissionLayer()
    }
    
    override func tearDown() {
        sdkPermissionLayer = nil
        super.tearDown()
    }
    
    func testHasPermissionReturnsFalseByDefault() {
        XCTAssertFalse(sdkPermissionLayer.hasPermission(.camera, for: "test-app"))
    }
    
    func testGetPermissionsReturnsEmptyByDefault() {
        let permissions = sdkPermissionLayer.getPermissions(for: "test-app")
        XCTAssertTrue(permissions.isEmpty)
    }
    
    func testRevokePermissionRemovesIt() {
        // Manually test via the internal method through the SDKPermissionLayer
        let expectation = XCTestExpectation(description: "Permission revoked")
        
        sdkPermissionLayer.revokePermission(.camera, from: "test-app")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let hasPermission = self?.sdkPermissionLayer.hasPermission(.camera, for: "test-app") ?? true
            XCTAssertFalse(hasPermission)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
