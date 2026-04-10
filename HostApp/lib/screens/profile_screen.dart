import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();
    final notifService = Get.find<NotificationService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.snackbar(
              'Edit Profile',
              'Profile editing coming soon',
              snackPosition: SnackPosition.TOP,
            ),
          ),
        ],
      ),
      body: Obx(() {
        final user = authService.currentUser.value;
        if (user == null) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 52,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 40,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Info card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _infoTile(Icons.phone_outlined, 'Phone',
                        user.phone ?? 'Not set', context),
                    const Divider(height: 1, indent: 56),
                    _infoTile(Icons.fingerprint, 'Biometric Auth',
                        user.biometricEnabled ? 'Enabled' : 'Disabled',
                        context,
                        trailing: Switch(
                          value: user.biometricEnabled,
                          onChanged: (_) {},
                        )),
                    const Divider(height: 1, indent: 56),
                    _infoTile(
                        Icons.notifications_outlined,
                        'Notifications',
                        '${notifService.unreadCount.value} unread',
                        context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('3', 'Apps Installed', context),
                      _stat('12', 'Transactions', context),
                      _stat('5', 'Days Active', context),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Logout
              OutlinedButton.icon(
                onPressed: () async {
                  await authService.logout();
                  Get.offAll(() => const LoginScreen());
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _infoTile(
      IconData icon, String title, String subtitle, BuildContext context,
      {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }

  Widget _stat(String value, String label, BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
