import 'package:get/get.dart';
import '../models/payment.dart';

class PaymentService extends GetxService {
  final RxList<Payment> transactions = <Payment>[].obs;
  final RxBool isProcessing = false.obs;

  Future<Payment?> processPayment({
    required double amount,
    required PaymentMethod method,
    String? merchantId,
    String? description,
  }) async {
    isProcessing.value = true;
    try {
      await Future.delayed(const Duration(seconds: 2));

      final payment = Payment(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        method: method,
        status: PaymentStatus.success,
        merchantId: merchantId,
        description: description,
        createdAt: DateTime.now(),
      );

      transactions.add(payment);
      return payment;
    } finally {
      isProcessing.value = false;
    }
  }

  List<Payment> getTransactionHistory() => transactions.toList();
}
