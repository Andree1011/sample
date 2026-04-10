import Foundation

/// Manages payment transactions, tracking, and history.
public class TransactionManager {
    
    // MARK: - Properties
    
    private var transactions: [String: Transaction] = [:]
    private let queue = DispatchQueue(label: "com.miniapp.sdk.transactions", attributes: .concurrent)
    
    // MARK: - Initializer
    
    public init() {}
    
    // MARK: - Public Methods
    
    /// Create a new transaction.
    /// - Parameter transaction: The transaction to create.
    public func create(transaction: Transaction) {
        queue.async(flags: .barrier) { [weak self] in
            self?.transactions[transaction.transactionId] = transaction
        }
    }
    
    /// Update the status of an existing transaction.
    /// - Parameters:
    ///   - transactionId: The identifier of the transaction.
    ///   - status: The new status.
    /// - Throws: `MiniAppError` if transaction not found.
    public func updateStatus(transactionId: String, status: Transaction.Status) throws {
        try queue.sync(flags: .barrier) {
            guard var transaction = self.transactions[transactionId] else {
                throw MiniAppError.transactionNotFound(transactionId)
            }
            transaction.status = status
            transaction.updatedAt = Date()
            self.transactions[transactionId] = transaction
        }
    }
    
    /// Get a transaction by its identifier.
    /// - Parameter transactionId: The transaction identifier.
    /// - Returns: The transaction.
    /// - Throws: `MiniAppError` if not found.
    public func getTransaction(transactionId: String) throws -> Transaction {
        guard let transaction = queue.sync(execute: { transactions[transactionId] }) else {
            throw MiniAppError.transactionNotFound(transactionId)
        }
        return transaction
    }
    
    /// Get all transactions.
    /// - Returns: Array of all transactions.
    public func getAllTransactions() -> [Transaction] {
        return queue.sync { Array(transactions.values) }
    }
    
    /// Get transactions filtered by status.
    /// - Parameter status: The status to filter by.
    /// - Returns: Filtered array of transactions.
    public func getTransactions(with status: Transaction.Status) -> [Transaction] {
        return queue.sync {
            transactions.values.filter { $0.status == status }
        }
    }
    
    /// Remove a completed/failed transaction from tracking.
    /// - Parameter transactionId: The transaction identifier.
    public func remove(transactionId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.transactions.removeValue(forKey: transactionId)
        }
    }
    
    /// Clear all transactions.
    public func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.transactions.removeAll()
        }
    }
}
