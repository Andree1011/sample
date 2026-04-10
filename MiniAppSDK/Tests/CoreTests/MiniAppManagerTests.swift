import XCTest
@testable import MiniAppSDK

final class MiniAppManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        MiniAppManager.shared.reset()
    }
    
    override func tearDown() {
        MiniAppManager.shared.reset()
        super.tearDown()
    }
    
    func testSharedInstanceIsSingleton() {
        let instance1 = MiniAppManager.shared
        let instance2 = MiniAppManager.shared
        XCTAssertTrue(instance1 === instance2, "Shared instance should be the same object")
    }
    
    func testInitializationWithValidConfig() throws {
        let config = makeConfig()
        XCTAssertNoThrow(try MiniAppManager.shared.initialize(with: config))
        XCTAssertTrue(MiniAppManager.shared.isInitialized)
    }
    
    func testInitializationFailsWhenAlreadyInitialized() throws {
        let config = makeConfig()
        try MiniAppManager.shared.initialize(with: config)
        
        XCTAssertThrowsError(try MiniAppManager.shared.initialize(with: config)) { error in
            XCTAssertEqual(error as? MiniAppError, MiniAppError.alreadyInitialized)
        }
    }
    
    func testInitializationFailsWithInvalidConfig() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "", // Empty appId
            apiKey: "valid-key"
        )
        
        XCTAssertThrowsError(try MiniAppManager.shared.initialize(with: config)) { error in
            if case MiniAppError.invalidConfiguration(_) = error {
                // Expected
            } else {
                XCTFail("Expected invalidConfiguration error")
            }
        }
    }
    
    func testResetClearsInitialization() throws {
        let config = makeConfig()
        try MiniAppManager.shared.initialize(with: config)
        
        MiniAppManager.shared.reset()
        
        // Give async operations time to complete
        let expectation = XCTestExpectation(description: "Reset completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(MiniAppManager.shared.isInitialized)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetConfigReturnsNilBeforeInit() {
        XCTAssertNil(MiniAppManager.shared.getConfig())
    }
    
    func testGetConfigReturnsConfigAfterInit() throws {
        let config = makeConfig()
        try MiniAppManager.shared.initialize(with: config)
        
        let expectation = XCTestExpectation(description: "Config is set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(MiniAppManager.shared.getConfig())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCheckInitializedThrowsWhenNotInitialized() {
        XCTAssertThrowsError(try MiniAppManager.shared.checkInitialized()) { error in
            XCTAssertEqual(error as? MiniAppError, MiniAppError.notInitialized)
        }
    }
    
    // MARK: - Helpers
    
    private func makeConfig() -> MiniAppConfig {
        return MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app-id",
            apiKey: "test-api-key"
        )
    }
}
