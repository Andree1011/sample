import Foundation

/// Represents a payment transaction.
public struct Transaction: Codable {
    
    // MARK: - Types
    
    /// Transaction status
    public enum Status: String, Codable {
        case pending
        case processing
        case completed
        case failed
        case cancelled
        case refunded
    }
    
    /// Payment method type
    public enum PaymentMethod: String, Codable {
        case creditCard
        case debitCard
        case bankTransfer
        case digitalWallet
        case crypto
        case other
    }
    
    // MARK: - Properties
    
    /// Unique transaction identifier
    public let transactionId: String
    
    /// Amount in smallest currency unit (e.g., cents)
    public let amount: Int64
    
    /// Currency code (ISO 4217)
    public let currency: String
    
    /// Current transaction status
    public var status: Status
    
    /// Payment method used
    public let paymentMethod: PaymentMethod
    
    /// Transaction description
    public let description: String?
    
    /// Merchant identifier
    public let merchantId: String?
    
    /// Reference for external payment systems
    public let externalReference: String?
    
    /// Timestamp when transaction was created
    public let createdAt: Date
    
    /// Timestamp when transaction was last updated
    public var updatedAt: Date
    
    /// Additional metadata
    public let metadata: [String: String]
    
    // MARK: - Computed Properties
    
    /// Amount as a decimal value
    public var amountDecimal: Double {
        return Double(amount) / 100.0
    }
    
    /// Whether the transaction is in a terminal state
    public var isTerminal: Bool {
        switch status {
        case .completed, .failed, .cancelled, .refunded:
            return true
        case .pending, .processing:
            return false
        }
    }
    
    // MARK: - Initializer
    
    public init(
        transactionId: String = UUID().uuidString,
        amount: Int64,
        currency: String,
        status: Status = .pending,
        paymentMethod: PaymentMethod,
        description: String? = nil,
        merchantId: String? = nil,
        externalReference: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.transactionId = transactionId
        self.amount = amount
        self.currency = currency
        self.status = status
        self.paymentMethod = paymentMethod
        self.description = description
        self.merchantId = merchantId
        self.externalReference = externalReference
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
