import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/mini_app_service.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final miniAppService = Get.find<MiniAppService>();
    final paymentService = Get.find<PaymentService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Appearance', context),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Follow system theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: Get.isDarkMode,
                  onChanged: (v) => Get.changeThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Permissions', context),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _permissionTile(
                    Icons.location_on_outlined, 'Location', 'Allowed', context),
                const Divider(height: 1, indent: 56),
                _permissionTile(
                    Icons.camera_alt_outlined, 'Camera', 'Allowed', context),
                const Divider(height: 1, indent: 56),
                _permissionTile(Icons.notifications_outlined, 'Notifications',
                    'Allowed', context),
                const Divider(height: 1, indent: 56),
                _permissionTile(
                    Icons.bluetooth, 'Bluetooth', 'Not set', context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Payments', context),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Payment Methods'),
                  subtitle: const Text('Visa •••• 4242'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                Obx(() => ListTile(
                      leading: const Icon(Icons.receipt_outlined),
                      title: const Text('Transaction History'),
                      subtitle: Text(
                          '${paymentService.transactions.length} transactions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showTransactionHistory(
                          context, paymentService.transactions),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('Mini Apps', context),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Obx(() => ListTile(
                      leading: const Icon(Icons.apps),
                      title: const Text('Installed Apps'),
                      subtitle: Text(
                          '${miniAppService.installedApps.length} apps installed'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    )),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Cache & Storage'),
                  subtitle: const Text('12.4 MB used'),
                  trailing: TextButton(
                    onPressed: () => Get.snackbar(
                      'Cache Cleared',
                      'All cached data has been removed',
                      snackPosition: SnackPosition.TOP,
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader('About', context),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0 (Demo)'),
                ),
                const Divider(height: 1, indent: 56),
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('SDK Version'),
                  subtitle: Text('MiniApp SDK v1.0.0'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _permissionTile(
      IconData icon, String title, String status, BuildContext context) {
    final allowed = status == 'Allowed';
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: allowed
              ? Colors.green.withAlpha(30)
              : Colors.orange.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: allowed ? Colors.green : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () {},
    );
  }

  void _showTransactionHistory(
      BuildContext context, List<Payment> transactions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Transaction History',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (_, i) {
                        final t = transactions[i];
                        return ListTile(
                          leading: const Icon(Icons.receipt),
                          title: Text(t.description ?? 'Payment'),
                          subtitle: Text(t.createdAt.toLocal().toString()),
                          trailing: Text(
                            '\$${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: t.status == PaymentStatus.success
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
