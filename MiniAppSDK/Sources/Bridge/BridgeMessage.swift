import Foundation

/// Represents a message exchanged via the Mini App Bridge.
public struct BridgeMessage: Codable {
    
    // MARK: - Types
    
    /// Message type
    public enum MessageType: String, Codable {
        case request
        case response
        case event
        case error
    }
    
    // MARK: - Properties
    
    /// Unique message identifier
    public let messageId: String
    
    /// Type of the message
    public let type: MessageType
    
    /// Method name being invoked
    public let method: String
    
    /// Message payload data
    public let payload: [String: AnyCodable]
    
    /// Correlation ID linking request to response
    public let correlationId: String?
    
    /// Timestamp of the message
    public let timestamp: Date
    
    /// Source identifier (app ID or host)
    public let source: String
    
    /// Target identifier (app ID or host)
    public let target: String?
    
    // MARK: - Initializer
    
    public init(
        messageId: String = UUID().uuidString,
        type: MessageType,
        method: String,
        payload: [String: AnyCodable] = [:],
        correlationId: String? = nil,
        timestamp: Date = Date(),
        source: String,
        target: String? = nil
    ) {
        self.messageId = messageId
        self.type = type
        self.method = method
        self.payload = payload
        self.correlationId = correlationId
        self.timestamp = timestamp
        self.source = source
        self.target = target
    }
}

/// Type-erased Codable wrapper for handling mixed-type dictionaries.
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = ""
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
