import XCTest
@testable import MiniAppSDK

final class NotificationServiceTests: XCTestCase {
    
    var notificationService: NotificationService!
    
    override func setUp() {
        super.setUp()
        notificationService = NotificationService()
    }
    
    override func tearDown() {
        notificationService.cancelAllNotifications()
        notificationService = nil
        super.tearDown()
    }
    
    func testLocalNotificationInitialization() {
        let notification = LocalNotification(
            title: "Test Title",
            body: "Test Body"
        )
        
        XCTAssertEqual(notification.title, "Test Title")
        XCTAssertEqual(notification.body, "Test Body")
        XCTAssertFalse(notification.identifier.isEmpty)
        XCTAssertNil(notification.scheduledDate)
        XCTAssertNil(notification.subtitle)
    }
    
    func testLocalNotificationWithCustomIdentifier() {
        let notification = LocalNotification(
            identifier: "custom-id",
            title: "Test",
            body: "Body"
        )
        XCTAssertEqual(notification.identifier, "custom-id")
    }
    
    func testNotificationManagerCancelAll() {
        // Simply test that cancelAll doesn't crash
        XCTAssertNoThrow(notificationService.cancelAllNotifications())
    }
    
    func testNotificationManagerCancelSpecific() {
        XCTAssertNoThrow(notificationService.cancelNotification(identifier: "test-id"))
    }
    
    func testGetPendingNotifications() {
        let expectation = XCTestExpectation(description: "Pending notifications retrieved")
        
        notificationService.getPendingNotifications { identifiers in
            // Just verify the call works (may be empty without authorization)
            XCTAssertNotNil(identifiers)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}
