import 'package:get/get.dart';
import '../models/mini_app.dart';
import '../services/bundle_manager.dart';
import '../utils/mock_data.dart';

class MiniAppService extends GetxService {
  final RxList<MiniApp> installedApps = <MiniApp>[].obs;
  final RxList<MiniApp> marketplaceApps = <MiniApp>[].obs;
  final RxBool isLoading = false.obs;
  final RxString downloadProgress = ''.obs;

  late final BundleManager _bundleManager;

  @override
  void onInit() {
    super.onInit();
    _bundleManager = Get.find<BundleManager>();
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

  /// Downloads and installs a mini app bundle.
  ///
  /// For built-in apps (shopping / health / chat) the bundle is already
  /// shipped as a Flutter asset and is extracted on first open, so this
  /// method just marks them as installed immediately.
  Future<bool> installApp(MiniApp app) async {
    isLoading.value = true;
    downloadProgress.value = 'Downloading...';
    try {
      final isBuiltin = _isBuiltinApp(app.id);
      String localPath;

      if (isBuiltin) {
        // Extract from Flutter assets (no network needed)
        downloadProgress.value = 'Extracting bundle...';
        localPath = await _bundleManager.getBuiltinBundlePath('${app.id}-bundle');
      } else {
        // Download real ZIP from the bundle URL
        localPath = await _bundleManager.downloadBundle(
          appId: app.id,
          url: app.bundleUrl,
          onProgress: (p) {
            downloadProgress.value =
                'Downloading... ${(p * 100).toStringAsFixed(0)}%';
          },
        );
      }

      downloadProgress.value = 'Installing...';
      await Future.delayed(const Duration(milliseconds: 300));

      app.isInstalled = true;
      app.localBundlePath = localPath;

      if (!installedApps.any((a) => a.id == app.id)) {
        installedApps.add(app);
      }

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
    await _bundleManager.clearCache(appId);
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

  bool _isBuiltinApp(String id) =>
      id == 'shopping' || id == 'health' || id == 'chat';
}
