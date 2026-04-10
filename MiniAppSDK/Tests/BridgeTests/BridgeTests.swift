import XCTest
@testable import MiniAppSDK

final class BridgeTests: XCTestCase {
    
    var methodInvoker: MethodInvoker!
    
    override func setUp() {
        super.setUp()
        methodInvoker = MethodInvoker()
    }
    
    override func tearDown() {
        methodInvoker = nil
        super.tearDown()
    }
    
    // MARK: - MethodInvoker Tests
    
    func testRegisterAndInvokeMethod() {
        let expectation = XCTestExpectation(description: "Method invoked")
        
        methodInvoker.register(method: "testMethod") { params, completion in
            completion(.success(["result": "success"]))
        }
        
        methodInvoker.invoke(method: "testMethod", parameters: [:]) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response["result"] as? String, "success")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testInvokeUnregisteredMethodFails() {
        let expectation = XCTestExpectation(description: "Unregistered method fails")
        
        methodInvoker.invoke(method: "nonexistentMethod", parameters: [:]) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                if case MiniAppError.bridgeMethodNotFound(_) = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected bridgeMethodNotFound error")
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testUnregisterMethod() {
        methodInvoker.register(method: "tempMethod") { _, completion in
            completion(.success([:]))
        }
        
        XCTAssertTrue(methodInvoker.isMethodRegistered("tempMethod"))
        
        methodInvoker.unregister(method: "tempMethod")
        
        let expectation = XCTestExpectation(description: "Method unregistered")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertFalse(self?.methodInvoker.isMethodRegistered("tempMethod") ?? true)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testIsMethodRegistered() {
        XCTAssertFalse(methodInvoker.isMethodRegistered("unregistered"))
        
        methodInvoker.register(method: "registered") { _, completion in
            completion(.success([:]))
        }
        
        let expectation = XCTestExpectation(description: "Method registration checked")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            XCTAssertTrue(self?.methodInvoker.isMethodRegistered("registered") ?? false)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testGetRegisteredMethods() {
        methodInvoker.register(method: "method1") { _, completion in completion(.success([:])) }
        methodInvoker.register(method: "method2") { _, completion in completion(.success([:])) }
        
        let expectation = XCTestExpectation(description: "Registered methods listed")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let methods = self?.methodInvoker.registeredMethods() ?? []
            XCTAssertTrue(methods.contains("method1"))
            XCTAssertTrue(methods.contains("method2"))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testInvokeMethodWithParameters() {
        let expectation = XCTestExpectation(description: "Method invoked with params")
        
        methodInvoker.register(method: "echoMethod") { params, completion in
            completion(.success(params))
        }
        
        let params = ["key": "value", "number": "42"]
        methodInvoker.invoke(method: "echoMethod", parameters: params) { result in
            if case .success(let response) = result {
                XCTAssertEqual(response["key"] as? String, "value")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - BridgeMessage Tests
    
    func testBridgeMessageInitialization() {
        let message = BridgeMessage(
            type: .request,
            method: "testMethod",
            source: "miniapp-1"
        )
        
        XCTAssertFalse(message.messageId.isEmpty)
        XCTAssertEqual(message.type, .request)
        XCTAssertEqual(message.method, "testMethod")
        XCTAssertEqual(message.source, "miniapp-1")
        XCTAssertNil(message.correlationId)
    }
    
    func testBridgeMessageTypes() {
        XCTAssertEqual(BridgeMessage.MessageType.request.rawValue, "request")
        XCTAssertEqual(BridgeMessage.MessageType.response.rawValue, "response")
        XCTAssertEqual(BridgeMessage.MessageType.event.rawValue, "event")
        XCTAssertEqual(BridgeMessage.MessageType.error.rawValue, "error")
    }
    
    func testAnyCodableWithString() throws {
        let codable = AnyCodable("test string")
        let data = try JSONEncoder().encode(codable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? String, "test string")
    }
    
    func testAnyCodableWithInt() throws {
        let codable = AnyCodable(42)
        let data = try JSONEncoder().encode(codable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Int, 42)
    }
    
    func testAnyCodableWithBool() throws {
        let codable = AnyCodable(true)
        let data = try JSONEncoder().encode(codable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Bool, true)
    }
}
