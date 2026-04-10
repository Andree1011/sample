import Foundation

/// Service for processing payments and managing payment transactions.
public class PaymentService {
    
    // MARK: - Properties
    
    private let transactionManager: TransactionManager
    private let queue = DispatchQueue(label: "com.miniapp.sdk.payment", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {
        self.transactionManager = TransactionManager()
    }
    
    // MARK: - Public Methods
    
    /// Process a payment.
    /// - Parameters:
    ///   - amount: The payment amount in smallest currency unit.
    ///   - currency: Currency code (ISO 4217, e.g., "USD").
    ///   - paymentMethod: The payment method to use.
    ///   - description: Payment description (optional).
    ///   - metadata: Additional payment metadata.
    ///   - completion: Callback with the resulting transaction or an error.
    public func processPayment(
        amount: Int64,
        currency: String,
        paymentMethod: Transaction.PaymentMethod,
        description: String? = nil,
        metadata: [String: String] = [:],
        completion: @escaping (Result<Transaction, MiniAppError>) -> Void
    ) {
        guard amount > 0 else {
            completion(.failure(.invalidPaymentAmount))
            return
        }
        
        let transaction = Transaction(
            amount: amount,
            currency: currency,
            status: .processing,
            paymentMethod: paymentMethod,
            description: description,
            metadata: metadata
        )
        
        transactionManager.create(transaction: transaction)
        
        // Simulate payment processing
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // In production, this would integrate with a payment gateway
            do {
                try self.transactionManager.updateStatus(
                    transactionId: transaction.transactionId,
                    status: .completed
                )
                let updatedTransaction = try self.transactionManager.getTransaction(
                    transactionId: transaction.transactionId
                )
                completion(.success(updatedTransaction))
            } catch let error as MiniAppError {
                completion(.failure(error))
            } catch {
                completion(.failure(.paymentFailed(error.localizedDescription)))
            }
        }
    }
    
    /// Get a transaction by its identifier.
    /// - Parameter transactionId: The transaction identifier.
    /// - Returns: The transaction.
    /// - Throws: `MiniAppError` if not found.
    public func getTransaction(transactionId: String) throws -> Transaction {
        return try transactionManager.getTransaction(transactionId: transactionId)
    }
    
    /// Get all transactions.
    /// - Returns: Array of all transactions.
    public func getAllTransactions() -> [Transaction] {
        return transactionManager.getAllTransactions()
    }
    
    /// Cancel a pending transaction.
    /// - Parameters:
    ///   - transactionId: The transaction to cancel.
    ///   - completion: Callback indicating success or failure.
    public func cancelTransaction(
        transactionId: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        do {
            let transaction = try transactionManager.getTransaction(transactionId: transactionId)
            
            guard !transaction.isTerminal else {
                completion(.failure(.paymentFailed("Transaction is already in terminal state: \(transaction.status.rawValue)")))
                return
            }
            
            try transactionManager.updateStatus(transactionId: transactionId, status: .cancelled)
            completion(.success(()))
        } catch let error as MiniAppError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknown(error.localizedDescription)))
        }
    }
    
    /// Request a refund for a completed transaction.
    /// - Parameters:
    ///   - transactionId: The transaction to refund.
    ///   - completion: Callback indicating success or failure.
    public func refundTransaction(
        transactionId: String,
        completion: @escaping (Result<Void, MiniAppError>) -> Void
    ) {
        do {
            let transaction = try transactionManager.getTransaction(transactionId: transactionId)
            
            guard transaction.status == .completed else {
                completion(.failure(.paymentFailed("Only completed transactions can be refunded")))
                return
            }
            
            // Simulate refund processing
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
                do {
                    try self?.transactionManager.updateStatus(transactionId: transactionId, status: .refunded)
                    completion(.success(()))
                } catch let error as MiniAppError {
                    completion(.failure(error))
                } catch {
                    completion(.failure(.paymentFailed(error.localizedDescription)))
                }
            }
        } catch let error as MiniAppError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknown(error.localizedDescription)))
        }
    }
}
