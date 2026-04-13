import 'package:get/get.dart';
import '../models/user.dart';

class AuthService extends GetxService {
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isAuthenticated = false.obs;
  final RxBool isLoading = false.obs;

  /// Mock login - in production this would call a real API.
  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isNotEmpty && password.length >= 6) {
        currentUser.value = User(
          id: 'user_001',
          name: 'Alex Johnson',
          email: email,
          phone: '+1 (555) 123-4567',
          biometricEnabled: true,
          createdAt: DateTime(2023, 1, 15),
        );
        isAuthenticated.value = true;
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Mock biometric authentication.
  Future<bool> loginWithBiometric() async {
    isLoading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      currentUser.value = User(
        id: 'user_001',
        name: 'Alex Johnson',
        email: 'alex@example.com',
        phone: '+1 (555) 123-4567',
        biometricEnabled: true,
        createdAt: DateTime(2023, 1, 15),
      );
      isAuthenticated.value = true;
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    currentUser.value = null;
    isAuthenticated.value = false;
  }
}
