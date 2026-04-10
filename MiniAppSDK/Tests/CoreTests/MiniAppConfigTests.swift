import XCTest
@testable import MiniAppSDK

final class MiniAppConfigTests: XCTestCase {
    
    func testValidConfigPassesValidation() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app",
            apiKey: "test-key"
        )
        XCTAssertNoThrow(try config.validate())
    }
    
    func testEmptyAppIdFailsValidation() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "",
            apiKey: "test-key"
        )
        XCTAssertThrowsError(try config.validate()) { error in
            if case MiniAppError.invalidConfiguration(let message) = error {
                XCTAssertTrue(message.contains("appId"))
            } else {
                XCTFail("Expected invalidConfiguration error")
            }
        }
    }
    
    func testEmptyApiKeyFailsValidation() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app",
            apiKey: ""
        )
        XCTAssertThrowsError(try config.validate()) { error in
            if case MiniAppError.invalidConfiguration(let message) = error {
                XCTAssertTrue(message.contains("apiKey"))
            } else {
                XCTFail("Expected invalidConfiguration error")
            }
        }
    }
    
    func testNegativeTimeoutFailsValidation() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app",
            apiKey: "test-key",
            requestTimeout: -1
        )
        XCTAssertThrowsError(try config.validate())
    }
    
    func testZeroMaxCachedAppsFailsValidation() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app",
            apiKey: "test-key",
            maxCachedApps: 0
        )
        XCTAssertThrowsError(try config.validate())
    }
    
    func testDefaultValues() {
        let config = MiniAppConfig(
            baseURL: URL(string: "https://example.com")!,
            appId: "test-app",
            apiKey: "test-key"
        )
        XCTAssertEqual(config.environment, .production)
        XCTAssertEqual(config.requestTimeout, 30)
        XCTAssertEqual(config.maxCachedApps, 10)
        XCTAssertFalse(config.debugLoggingEnabled)
        XCTAssertNil(config.certificatePinningConfig)
    }
}
