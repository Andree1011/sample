import 'package:get/get.dart';
import '../models/mini_app.dart';
import '../utils/mock_data.dart';

class MiniAppService extends GetxService {
  final RxList<MiniApp> installedApps = <MiniApp>[].obs;
  final RxList<MiniApp> marketplaceApps = <MiniApp>[].obs;
  final RxBool isLoading = false.obs;
  final RxString downloadProgress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInstalledApps();
    _loadMarketplace();
  }

  void _loadInstalledApps() {
    installedApps.assignAll(MockData.installedApps);
  }

  Future<void> _loadMarketplace() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    marketplaceApps.assignAll(MockData.marketplaceApps);
    isLoading.value = false;
  }

  /// Simulate downloading and installing a mini app bundle.
  Future<bool> installApp(MiniApp app) async {
    isLoading.value = true;
    downloadProgress.value = 'Downloading...';
    try {
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        downloadProgress.value = 'Downloading... $i%';
      }
      downloadProgress.value = 'Installing...';
      await Future.delayed(const Duration(milliseconds: 400));

      app.isInstalled = true;
      app.localBundlePath = '/bundles/${app.id}-bundle';

      // Add to installed apps if not already there
      if (!installedApps.any((a) => a.id == app.id)) {
        installedApps.add(app);
      }

      // Refresh marketplace list
      final idx = marketplaceApps.indexWhere((a) => a.id == app.id);
      if (idx != -1) {
        marketplaceApps[idx].isInstalled = true;
        marketplaceApps.refresh();
      }

      downloadProgress.value = '';
      return true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> uninstallApp(String appId) async {
    installedApps.removeWhere((a) => a.id == appId);
    final idx = marketplaceApps.indexWhere((a) => a.id == appId);
    if (idx != -1) {
      marketplaceApps[idx].isInstalled = false;
      marketplaceApps.refresh();
    }
    return true;
  }

  MiniApp? getApp(String appId) {
    return installedApps.firstWhereOrNull((a) => a.id == appId);
  }
}
