import XCTest
@testable import MiniAppSDK

final class PaymentServiceTests: XCTestCase {
    
    var paymentService: PaymentService!
    
    override func setUp() {
        super.setUp()
        paymentService = PaymentService()
    }
    
    override func tearDown() {
        paymentService = nil
        super.tearDown()
    }
    
    func testProcessPaymentSucceeds() {
        let expectation = XCTestExpectation(description: "Payment processed")
        
        paymentService.processPayment(
            amount: 1000,
            currency: "USD",
            paymentMethod: .creditCard,
            description: "Test payment"
        ) { result in
            switch result {
            case .success(let transaction):
                XCTAssertEqual(transaction.amount, 1000)
                XCTAssertEqual(transaction.currency, "USD")
                XCTAssertEqual(transaction.status, .completed)
                XCTAssertEqual(transaction.paymentMethod, .creditCard)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success but got: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testProcessPaymentWithZeroAmountFails() {
        let expectation = XCTestExpectation(description: "Payment fails with zero amount")
        
        paymentService.processPayment(
            amount: 0,
            currency: "USD",
            paymentMethod: .creditCard
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error, MiniAppError.invalidPaymentAmount)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testProcessPaymentWithNegativeAmountFails() {
        let expectation = XCTestExpectation(description: "Payment fails with negative amount")
        
        paymentService.processPayment(
            amount: -500,
            currency: "USD",
            paymentMethod: .creditCard
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                XCTAssertEqual(error, MiniAppError.invalidPaymentAmount)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGetTransactionAfterPayment() {
        let expectation = XCTestExpectation(description: "Transaction retrieved")
        
        paymentService.processPayment(
            amount: 500,
            currency: "USD",
            paymentMethod: .debitCard
        ) { [weak self] result in
            if case .success(let transaction) = result {
                do {
                    let retrieved = try self?.paymentService.getTransaction(
                        transactionId: transaction.transactionId
                    )
                    XCTAssertEqual(retrieved?.transactionId, transaction.transactionId)
                    expectation.fulfill()
                } catch {
                    XCTFail("Expected to find transaction")
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testGetNonexistentTransactionThrows() {
        XCTAssertThrowsError(try paymentService.getTransaction(transactionId: "nonexistent")) { error in
            if case MiniAppError.transactionNotFound(_) = error {
                // Expected
            } else {
                XCTFail("Expected transactionNotFound error")
            }
        }
    }
    
    func testCancelPendingTransaction() {
        let expectation = XCTestExpectation(description: "Transaction cancelled")
        
        // Create a transaction manually to cancel
        let transactionManager = TransactionManager()
        let transaction = Transaction(
            amount: 1000,
            currency: "USD",
            status: .pending,
            paymentMethod: .bankTransfer
        )
        transactionManager.create(transaction: transaction)
        
        // Using TransactionManager directly to test cancel
        XCTAssertNoThrow(try transactionManager.updateStatus(
            transactionId: transaction.transactionId,
            status: .cancelled
        ))
        
        let updated = try? transactionManager.getTransaction(transactionId: transaction.transactionId)
        XCTAssertEqual(updated?.status, .cancelled)
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testTransactionAmountDecimal() {
        let transaction = Transaction(
            amount: 1099,
            currency: "USD",
            paymentMethod: .creditCard
        )
        XCTAssertEqual(transaction.amountDecimal, 10.99)
    }
    
    func testTransactionIsTerminal() {
        let completedTransaction = Transaction(
            amount: 1000,
            currency: "USD",
            status: .completed,
            paymentMethod: .creditCard
        )
        XCTAssertTrue(completedTransaction.isTerminal)
        
        let pendingTransaction = Transaction(
            amount: 1000,
            currency: "USD",
            status: .pending,
            paymentMethod: .creditCard
        )
        XCTAssertFalse(pendingTransaction.isTerminal)
    }
}
