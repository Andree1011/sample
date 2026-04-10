enum PaymentStatus { pending, processing, success, failed, cancelled }

enum PaymentMethod { creditCard, debitCard, bankTransfer, wallet }

class Payment {
  final String id;
  final double amount;
  final String currency;
  final PaymentMethod method;
  PaymentStatus status;
  final String? merchantId;
  final String? description;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    required this.method,
    this.status = PaymentStatus.pending,
    this.merchantId,
    this.description,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      method: PaymentMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => PaymentMethod.wallet,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      merchantId: json['merchant_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'method': method.name,
        'status': status.name,
        'merchant_id': merchantId,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };
}
