import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/mini_app.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

class MiniAppContainerScreen extends StatefulWidget {
  final MiniApp miniApp;

  const MiniAppContainerScreen({super.key, required this.miniApp});

  @override
  State<MiniAppContainerScreen> createState() =>
      _MiniAppContainerScreenState();
}

class _MiniAppContainerScreenState extends State<MiniAppContainerScreen> {
  final _paymentService = Get.find<PaymentService>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate mini app loading
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _handleBridgeCall(String method, Map<String, dynamic> params) {
    switch (method) {
      case 'payment.startPayment':
        _handlePayment(params);
        break;
      case 'notification.showNotification':
        _handleNotification(params);
        break;
      case 'auth.getUserInfo':
        _handleGetUserInfo();
        break;
      default:
        debugPrint('Unknown bridge method: $method');
    }
  }

  void _handlePayment(Map<String, dynamic> params) {
    final amount = (params['amount'] as num?)?.toDouble() ?? 0.0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('Payment Request',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('\$${amount.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: Colors.green)),
            const SizedBox(height: 8),
            Text(params['description'] as String? ?? 'Payment',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _paymentService.processPayment(
                        amount: amount,
                        method: PaymentMethod.wallet,
                        description: params['description'] as String?,
                      );
                      if (mounted) {
                        Get.snackbar(
                          'Payment Successful',
                          '\$${amount.toStringAsFixed(2)} paid',
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                        );
                      }
                    },
                    child: const Text('Pay Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotification(Map<String, dynamic> params) {
    Get.snackbar(
      params['title'] as String? ?? 'Notification',
      params['body'] as String? ?? '',
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleGetUserInfo() {
    Get.snackbar(
      'User Info Shared',
      'Profile data shared with mini app',
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.miniApp.emojiIcon,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(widget.miniApp.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showAppOptions(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Loading ${widget.miniApp.name}...',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : _buildMiniAppContent(),
    );
  }

  Widget _buildMiniAppContent() {
    // In a real implementation, this would use WKWebView (iOS) or WebView
    // to load the mini app bundle. For demo purposes, we show a native UI
    // representation of the mini app.
    switch (widget.miniApp.id) {
      case 'shopping':
        return _buildShoppingDemo();
      case 'health':
        return _buildHealthDemo();
      case 'chat':
        return _buildChatDemo();
      default:
        return _buildGenericDemo();
    }
  }

  Widget _buildShoppingDemo() {
    final products = [
      {'name': 'Wireless Headphones', 'price': 79.99, 'emoji': '🎧'},
      {'name': 'Smart Watch', 'price': 199.99, 'emoji': '⌚'},
      {'name': 'Running Shoes', 'price': 89.99, 'emoji': '👟'},
      {'name': 'Yoga Mat', 'price': 29.99, 'emoji': '🧘'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer.withAlpha(60),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleBridgeCall('payment.startPayment', {
                    'amount': p['price'],
                    'description': 'Buy ${p['name']}',
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p['emoji'] as String,
                            style: const TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        Text(p['name'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('\$${(p['price'] as double).toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () => _handleBridgeCall(
                              'payment.startPayment', {
                            'amount': p['price'],
                            'description': 'Buy ${p['name']}',
                          }),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(32),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Add to Cart',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today\'s Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metricCard('👣', '8,234', 'Steps', '82%')),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('🔥', '412', 'Calories', '68%')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricCard('❤️', '72', 'Heart Rate', null)),
              const SizedBox(width: 12),
              Expanded(
                  child: _metricCard('😴', '7h 20m', 'Sleep', '88%')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Activity This Week',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActivityChart(),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _handleBridgeCall(
                'permission.requestPermission', {'type': 'camera'}),
            icon: const Icon(Icons.bluetooth),
            label: const Text('Connect IoT Device'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
      String emoji, String value, String label, String? progress) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: double.parse(progress.replaceAll('%', '')) / 100,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(progress,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [0.6, 0.8, 0.5, 0.9, 0.7, 0.4, 0.82];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(days.length, (i) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 28,
                    height: 80 * values[i],
                    decoration: BoxDecoration(
                      color: i == 6
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[i],
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildChatDemo() {
    final messages = [
      {'sender': 'Sarah', 'text': 'Hey! Are you available?', 'mine': false},
      {'sender': 'Me', 'text': 'Yes, what\'s up?', 'mine': true},
      {
        'sender': 'Sarah',
        'text': 'Can you help me with the project?',
        'mine': false
      },
      {
        'sender': 'Me',
        'text': 'Sure! Let me check the files first.',
        'mine': true
      },
      {'sender': 'Sarah', 'text': 'Great, thanks! 🙏', 'mine': false},
    ];

    return Column(
      children: [
        // Contact list header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const CircleAvatar(child: Text('S')),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sarah',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('Online',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final msg = messages[i];
              final isMine = msg['mine'] as bool;
              return Align(
                alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMine
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isMine
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                  ),
                  constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.7),
                  child: Text(
                    msg['text'] as String,
                    style: TextStyle(
                        color: isMine ? Colors.white : null),
                  ),
                ),
              );
            },
          ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _handleBridgeCall(
                    'notification.showNotification',
                    {'title': 'Message Sent', 'body': 'Your message was sent'}),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenericDemo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.miniApp.emojiIcon,
              style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(widget.miniApp.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(widget.miniApp.description,
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showAppOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                Future.delayed(const Duration(milliseconds: 600),
                    () => setState(() => _isLoading = false));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info'),
              subtitle: Text('v${widget.miniApp.version}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Uninstall',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
