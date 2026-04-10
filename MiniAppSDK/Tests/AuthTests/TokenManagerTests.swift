import XCTest
@testable import MiniAppSDK

final class TokenManagerTests: XCTestCase {
    
    var tokenManager: TokenManager!
    
    override func setUp() {
        super.setUp()
        tokenManager = TokenManager()
    }
    
    override func tearDown() {
        tokenManager.clearTokens()
        tokenManager = nil
        super.tearDown()
    }
    
    func testTokenIsExpiredByDefault() {
        XCTAssertTrue(tokenManager.isTokenExpired())
    }
    
    func testTokenIsNotValidByDefault() {
        XCTAssertFalse(tokenManager.isTokenValid())
    }
    
    func testStoreTokens() {
        let expiresAt = Date().addingTimeInterval(3600)
        tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: expiresAt
        )
        
        let expectation = XCTestExpectation(description: "Tokens stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertEqual(self?.tokenManager.getAccessToken(), "access-token")
            XCTAssertEqual(self?.tokenManager.getRefreshToken(), "refresh-token")
            XCTAssertFalse(self?.tokenManager.isTokenExpired() ?? true)
            XCTAssertTrue(self?.tokenManager.isTokenValid() ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testTokenIsExpiredWhenPastExpiry() {
        let expiredDate = Date().addingTimeInterval(-3600) // 1 hour ago
        tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: expiredDate
        )
        
        let expectation = XCTestExpectation(description: "Token expired check")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertTrue(self?.tokenManager.isTokenExpired() ?? false)
            XCTAssertFalse(self?.tokenManager.isTokenValid() ?? true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testClearTokens() {
        let expiresAt = Date().addingTimeInterval(3600)
        tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: expiresAt
        )
        tokenManager.clearTokens()
        
        let expectation = XCTestExpectation(description: "Tokens cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertNil(self?.tokenManager.getAccessToken())
            XCTAssertNil(self?.tokenManager.getRefreshToken())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRefreshToken() {
        let expectation = XCTestExpectation(description: "Token refreshed")
        
        tokenManager.refreshToken(currentToken: "old-refresh-token") { [weak self] result in
            switch result {
            case .success(let newToken):
                XCTAssertFalse(newToken.isEmpty)
                XCTAssertEqual(self?.tokenManager.getAccessToken(), newToken)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testRefreshTokenFailsWithEmptyToken() {
        let expectation = XCTestExpectation(description: "Refresh fails with empty token")
        
        tokenManager.refreshToken(currentToken: "") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if case MiniAppError.tokenRefreshFailed(_) = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected tokenRefreshFailed error")
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testTimeUntilExpiration() {
        let expiresAt = Date().addingTimeInterval(3600)
        tokenManager.storeTokens(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: expiresAt
        )
        
        let expectation = XCTestExpectation(description: "Time until expiration")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let timeLeft = self?.tokenManager.timeUntilExpiration() ?? 0
            XCTAssertGreaterThan(timeLeft, 3500)
            XCTAssertLessThanOrEqual(timeLeft, 3600)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
