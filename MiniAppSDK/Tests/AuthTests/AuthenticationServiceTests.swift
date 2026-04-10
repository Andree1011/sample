import XCTest
@testable import MiniAppSDK

final class AuthenticationServiceTests: XCTestCase {
    
    var authService: AuthenticationService!
    
    override func setUp() {
        super.setUp()
        authService = AuthenticationService()
    }
    
    override func tearDown() {
        authService.signOut()
        authService = nil
        super.tearDown()
    }
    
    func testSignInWithValidCredentials() {
        let expectation = XCTestExpectation(description: "Sign in succeeds")
        
        authService.signIn(username: "testuser", password: "password123") { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.username, "testuser")
                XCTAssertFalse(user.accessToken.isEmpty)
                XCTAssertFalse(user.refreshToken.isEmpty)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSignInWithEmptyUsernameFailsValidation() {
        let expectation = XCTestExpectation(description: "Sign in fails with empty username")
        
        authService.signIn(username: "", password: "password") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error, MiniAppError.invalidCredentials)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSignInWithEmptyPasswordFailsValidation() {
        let expectation = XCTestExpectation(description: "Sign in fails with empty password")
        
        authService.signIn(username: "testuser", password: "") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error, MiniAppError.invalidCredentials)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testIsAuthenticatedAfterSignIn() {
        let expectation = XCTestExpectation(description: "Authenticated after sign in")
        
        authService.signIn(username: "testuser", password: "password123") { [weak self] result in
            if case .success = result {
                let isAuthenticated = self?.authService.isAuthenticated ?? false
                XCTAssertTrue(isAuthenticated)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testSignOutClearsAuthentication() {
        let expectation = XCTestExpectation(description: "Signed out")
        
        authService.signIn(username: "testuser", password: "password123") { [weak self] result in
            if case .success = result {
                self?.authService.signOut()
                let isAuthenticated = self?.authService.isAuthenticated ?? true
                XCTAssertFalse(isAuthenticated)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGetCurrentUserReturnsNilBeforeSignIn() {
        XCTAssertNil(authService.getCurrentUser())
    }
    
    func testGetCurrentUserReturnsUserAfterSignIn() {
        let expectation = XCTestExpectation(description: "Current user is set")
        
        authService.signIn(username: "testuser", password: "password123") { [weak self] result in
            if case .success = result {
                let user = self?.authService.getCurrentUser()
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.username, "testuser")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGetAccessTokenThrowsWhenNotAuthenticated() {
        XCTAssertThrowsError(try authService.getAccessToken()) { error in
            XCTAssertEqual(error as? MiniAppError, MiniAppError.notAuthenticated)
        }
    }
    
    func testGetAccessTokenSucceedsWhenAuthenticated() {
        let expectation = XCTestExpectation(description: "Access token retrieved")
        
        authService.signIn(username: "testuser", password: "password123") { [weak self] result in
            if case .success = result {
                XCTAssertNoThrow(try self?.authService.getAccessToken())
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}
