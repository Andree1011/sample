import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/mini_app_service.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/mini_app_grid.dart';
import '../models/mini_app.dart';
import 'mini_app_container_screen.dart';
import 'marketplace_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _miniAppService = Get.put(MiniAppService());
  final _notificationService = Get.put(NotificationService());
  final _authService = Get.find<AuthService>();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
  }

  void _openMiniApp(MiniApp app) {
    Get.to(() => MiniAppContainerScreen(miniApp: app));
  }

  Widget _buildHomePage() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Obx(() => Text(
                    'Hello, ${_authService.currentUser.value?.name.split(' ').first ?? 'there'}! 👋',
                    style: const TextStyle(fontSize: 16),
                  )),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              Obx(() => Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () => _showNotifications(),
                      ),
                      if (_notificationService.unreadCount.value > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              '${_notificationService.unreadCount.value}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  )),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  Text(
                    'My Apps',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Obx(() => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: MiniAppGrid(
                  apps: _miniAppService.installedApps,
                  onAppTap: _openMiniApp,
                ),
              )),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _quickAction(Icons.store_outlined, 'Marketplace', () {
          setState(() => _currentIndex = 1);
        }),
        _quickAction(Icons.payment_outlined, 'Payments', () {
          setState(() => _currentIndex = 3);
        }),
        _quickAction(Icons.notifications_outlined, 'Alerts', _showNotifications),
        _quickAction(Icons.person_outline, 'Profile', () {
          setState(() => _currentIndex = 2);
        }),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon,
                color: Theme.of(context).colorScheme.primary, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() => ListView.builder(
                    controller: scrollController,
                    itemCount: _notificationService.notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notificationService.notifications[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(n.type == 'shopping'
                              ? '🛍️'
                              : n.type == 'health'
                                  ? '❤️'
                                  : '💬'),
                        ),
                        title: Text(n.title,
                            style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold)),
                        subtitle: Text(n.body),
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: () => _notificationService.markAsRead(n.id),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const MarketplaceScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
