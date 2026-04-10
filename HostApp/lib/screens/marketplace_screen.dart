import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/mini_app_service.dart';
import '../models/mini_app.dart';
import '../widgets/mini_app_card.dart';
import 'mini_app_container_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _miniAppService = Get.find<MiniAppService>();
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Shopping',
    'Health & Fitness',
    'Communication',
    'Food & Drink',
    'Travel',
    'Finance',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MiniApp> get _filteredApps {
    return _miniAppService.marketplaceApps.where((app) {
      final matchesCategory =
          _selectedCategory == 'All' || app.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _installApp(MiniApp app) async {
    Get.dialog(
      AlertDialog(
        title: Text('Install ${app.name}?'),
        content: Text(
            '${app.description}\n\nVersion: ${app.version}\nRating: ⭐ ${app.rating}'),
        actions: [
          TextButton(
              onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Get.back();
              final success = await _miniAppService.installApp(app);
              if (success) {
                Get.snackbar(
                  'Installed!',
                  '${app.name} is ready to use',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Install'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search mini apps...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                // Category filter
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == cat;
                      return FilterChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (_miniAppService.isLoading.value) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_miniAppService.downloadProgress.value.isNotEmpty
                  ? _miniAppService.downloadProgress.value
                  : 'Loading...'),
            ],
          );
        }

        final apps = _filteredApps;
        if (apps.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No mini apps found', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: apps.length,
          itemBuilder: (_, i) {
            final app = apps[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MiniAppCard(
                app: app,
                onTap: app.isInstalled
                    ? () => Get.to(() => MiniAppContainerScreen(miniApp: app))
                    : () => _installApp(app),
                onInstall:
                    app.isInstalled ? null : () => _installApp(app),
              ),
            );
          },
        );
      }),
    );
  }
}
