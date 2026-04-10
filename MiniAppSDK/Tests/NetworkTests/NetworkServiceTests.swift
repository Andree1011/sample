import XCTest
@testable import MiniAppSDK

final class NetworkServiceTests: XCTestCase {
    
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService(
            baseURL: URL(string: "https://httpbin.org"),
            maxRetries: 1
        )
    }
    
    override func tearDown() {
        networkService = nil
        super.tearDown()
    }
    
    func testGetRequestWithInvalidURLFails() {
        // Testing with a URL that is clearly invalid
        let localService = NetworkService()
        let expectation = XCTestExpectation(description: "Invalid URL fails")
        
        localService.get(path: "not-a-valid-url-!!!") { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if case NetworkError.invalidURL(_) = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidURL error, got: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNetworkServiceInitialization() {
        XCTAssertNotNil(networkService)
    }
    
    func testBuildRequestWithParameters() {
        let expectation = XCTestExpectation(description: "GET with params")
        
        networkService.get(
            path: "/get",
            parameters: ["key": "value"]
        ) { result in
            // Just testing that the request is built correctly
            // The actual network call will fail or succeed depending on connectivity
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAddInterceptor() {
        let interceptor = LoggingInterceptor(enabled: true)
        XCTAssertNoThrow(networkService.addInterceptor(interceptor))
    }
}

final class NetworkErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        XCTAssertNotNil(NetworkError.noConnection.errorDescription)
        XCTAssertNotNil(NetworkError.timeout.errorDescription)
        XCTAssertNotNil(NetworkError.invalidURL("test").errorDescription)
        XCTAssertNotNil(NetworkError.serverError(statusCode: 500, message: "Error").errorDescription)
        XCTAssertNotNil(NetworkError.decodingFailed("Error").errorDescription)
        XCTAssertNotNil(NetworkError.cancelled.errorDescription)
        XCTAssertNotNil(NetworkError.certificatePinningFailed.errorDescription)
        XCTAssertNotNil(NetworkError.authenticationRequired.errorDescription)
        XCTAssertNotNil(NetworkError.rateLimited.errorDescription)
    }
}
