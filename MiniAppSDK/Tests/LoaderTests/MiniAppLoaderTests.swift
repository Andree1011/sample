import XCTest
@testable import MiniAppSDK

final class MiniAppLoaderTests: XCTestCase {
    
    var loader: MiniAppLoader!
    
    override func setUp() {
        super.setUp()
        loader = MiniAppLoader()
    }
    
    override func tearDown() {
        loader = nil
        super.tearDown()
    }
    
    func testLoadAppSucceeds() {
        let expectation = XCTestExpectation(description: "App loaded")
        
        loader.loadApp(appId: "test-app") { result in
            switch result {
            case .success(let manifest):
                XCTAssertEqual(manifest.appId, "test-app")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testLoadAppWithEmptyIdFails() {
        let expectation = XCTestExpectation(description: "Load fails with empty ID")
        
        loader.loadApp(appId: "") { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error):
                XCTAssertEqual(error, MiniAppError.appNotFound(""))
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testLoadAppTwiceReturnsCachedManifest() {
        let expectation = XCTestExpectation(description: "Second load returns cached")
        expectation.expectedFulfillmentCount = 2
        
        var firstManifest: AppManifest?
        
        loader.loadApp(appId: "test-app") { result in
            if case .success(let manifest) = result {
                firstManifest = manifest
                expectation.fulfill()
            }
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.loader.loadApp(appId: "test-app") { result in
                if case .success(let manifest) = result {
                    XCTAssertEqual(manifest.appId, firstManifest?.appId)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testIsAppLoadedReturnsFalseBeforeLoad() {
        XCTAssertFalse(loader.isAppLoaded(appId: "test-app"))
    }
    
    func testIsAppLoadedReturnsTrueAfterLoad() {
        let expectation = XCTestExpectation(description: "App loaded")
        
        loader.loadApp(appId: "test-app") { [weak self] result in
            if case .success = result {
                let isLoaded = self?.loader.isAppLoaded(appId: "test-app") ?? false
                XCTAssertTrue(isLoaded)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testUnloadRemovesApp() {
        let expectation = XCTestExpectation(description: "App loaded then unloaded")
        
        loader.loadApp(appId: "test-app") { [weak self] result in
            if case .success = result {
                self?.loader.unloadApp(appId: "test-app")
                
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                    let isLoaded = self?.loader.isAppLoaded(appId: "test-app") ?? true
                    XCTAssertFalse(isLoaded)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGetLoadedApps() {
        let expectation = XCTestExpectation(description: "Apps loaded")
        expectation.expectedFulfillmentCount = 2
        
        loader.loadApp(appId: "app-1") { _ in expectation.fulfill() }
        loader.loadApp(appId: "app-2") { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: 3.0)
        
        let apps = loader.getLoadedApps()
        XCTAssertEqual(apps.count, 2)
    }
}
