import XCTest
@testable import MiniAppSDK

final class CacheManagerTests: XCTestCase {
    
    var cacheManager: CacheManager!
    
    override func setUp() {
        super.setUp()
        cacheManager = CacheManager(cachePolicy: CachePolicy(maxMemoryCacheSize: 5))
        cacheManager.clearAll()
    }
    
    override func tearDown() {
        cacheManager.clearAll()
        cacheManager = nil
        super.tearDown()
    }
    
    func testStoreAndRetrieve() throws {
        let data = "test data".data(using: .utf8)!
        try cacheManager.store(data: data, forKey: "test-key", version: "1.0")
        
        // Give async write time to complete
        let expectation = XCTestExpectation(description: "Cache stored")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let retrieved = try? self?.cacheManager.retrieve(forKey: "test-key")
            XCTAssertEqual(retrieved, data)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRetrieveMissingKeyThrowsCacheMiss() {
        XCTAssertThrowsError(try cacheManager.retrieve(forKey: "nonexistent-key")) { error in
            XCTAssertEqual(error as? MiniAppError, MiniAppError.cacheMiss)
        }
    }
    
    func testVersionMismatchThrowsError() throws {
        let data = "test data".data(using: .utf8)!
        try cacheManager.store(data: data, forKey: "versioned-key", version: "1.0")
        
        let expectation = XCTestExpectation(description: "Version mismatch")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            XCTAssertThrowsError(try self?.cacheManager.retrieve(forKey: "versioned-key", version: "2.0")) { error in
                if case MiniAppError.versionMismatch(_) = error {
                    // Expected
                } else {
                    XCTFail("Expected versionMismatch error")
                }
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testRemoveItem() throws {
        let data = "test data".data(using: .utf8)!
        try cacheManager.store(data: data, forKey: "remove-key", version: "1.0")
        
        let expectation = XCTestExpectation(description: "Item removed")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.cacheManager.remove(forKey: "remove-key")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                let contains = self?.cacheManager.contains(key: "remove-key") ?? true
                XCTAssertFalse(contains)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testContainsKey() throws {
        let data = "test data".data(using: .utf8)!
        try cacheManager.store(data: data, forKey: "contains-key", version: "1.0")
        
        let expectation = XCTestExpectation(description: "Contains check")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            let contains = self?.cacheManager.contains(key: "contains-key") ?? false
            XCTAssertTrue(contains)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testLRUEviction() throws {
        let policy = CachePolicy(maxMemoryCacheSize: 3)
        let smallCache = CacheManager(cachePolicy: policy)
        defer { smallCache.clearAll() }
        
        // Fill cache to capacity
        try smallCache.store(data: Data([1]), forKey: "key1", version: "1.0")
        try smallCache.store(data: Data([2]), forKey: "key2", version: "1.0")
        try smallCache.store(data: Data([3]), forKey: "key3", version: "1.0")
        
        // Add one more item to trigger LRU eviction
        try smallCache.store(data: Data([4]), forKey: "key4", version: "1.0")
        
        // Verify the cache handled the LRU eviction (no crash or error)
        XCTAssertTrue(smallCache.contains(key: "key4"))
    }
    
    func testClearAll() throws {
        let data = "test data".data(using: .utf8)!
        try cacheManager.store(data: data, forKey: "key1", version: "1.0")
        try cacheManager.store(data: data, forKey: "key2", version: "1.0")
        
        let expectation = XCTestExpectation(description: "Cache cleared")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.cacheManager.clearAll()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                let contains1 = self?.cacheManager.contains(key: "key1") ?? true
                let contains2 = self?.cacheManager.contains(key: "key2") ?? true
                XCTAssertFalse(contains1)
                XCTAssertFalse(contains2)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
