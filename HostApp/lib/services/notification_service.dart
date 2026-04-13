import 'package:get/get.dart';

class NotificationService extends GetxService {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadMockNotifications();
  }

  void _loadMockNotifications() {
    notifications.addAll([
      AppNotification(
        id: 'n1',
        title: 'Order Shipped',
        body: 'Your order #12345 has been shipped!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        type: 'shopping',
      ),
      AppNotification(
        id: 'n2',
        title: 'Daily Goal Achieved',
        body: "You've reached your step goal for today. Great work!",
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: false,
        type: 'health',
      ),
      AppNotification(
        id: 'n3',
        title: 'New Message',
        body: 'Sarah: Hey, are you available?',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        type: 'chat',
      ),
    ]);
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      notifications.refresh();
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    }
  }

  void addNotification(AppNotification notification) {
    notifications.insert(0, notification);
    if (!notification.isRead) {
      unreadCount.value++;
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String type;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
