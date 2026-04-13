import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Manages mini app bundle extraction and local caching.
///
/// Bundles ship as Flutter assets for the three built-in apps.
/// Downloaded bundles are extracted to the app's support directory and
/// served to the WebView via the `file://` scheme.
class BundleManager extends GetxService {
  static const _bundlesDir = 'mini_app_bundles';

  /// Maps mini-app id → directory on disk that contains `index.html`.
  final _cache = <String, String>{};

  // ---------------------------------------------------------------------------
  // Asset-backed bundles (Shopping / Health / Chat ship with the host app)
  // ---------------------------------------------------------------------------

  /// Returns the local directory path for a built-in mini app, extracting
  /// it from Flutter assets if not already cached.
  Future<String> getBuiltinBundlePath(String appId) async {
    if (_cache.containsKey(appId)) return _cache[appId]!;

    final dir = await _bundleDir(appId);
    if (!await _hasIndex(dir)) {
      await _extractAssetBundle(appId, dir);
    }
    _cache[appId] = dir.path;
    return dir.path;
  }

  // ---------------------------------------------------------------------------
  // Downloadable bundles
  // ---------------------------------------------------------------------------

  /// Downloads a ZIP from [url], extracts it, and returns the local path.
  /// Progress is reported via [onProgress] (0.0 – 1.0).
  Future<String> downloadBundle({
    required String appId,
    required String url,
    void Function(double)? onProgress,
  }) async {
    final dir = await _bundleDir(appId);

    final request = http.Request('GET', Uri.parse(url));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Bundle download failed: HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    int received = 0;
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }

    onProgress?.call(1.0);

    // Extract ZIP
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final file in archive) {
      final filePath = '${dir.path}/${file.name}';
      if (file.isFile) {
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(filePath).create(recursive: true);
      }
    }

    _cache[appId] = dir.path;
    return dir.path;
  }

  // ---------------------------------------------------------------------------
  // Cache helpers
  // ---------------------------------------------------------------------------

  /// Returns true if a bundle is already extracted on disk.
  Future<bool> isCached(String appId) async {
    if (_cache.containsKey(appId)) return true;
    final dir = await _bundleDir(appId);
    return _hasIndex(dir);
  }

  /// Deletes the cached bundle for [appId].
  Future<void> clearCache(String appId) async {
    final dir = await _bundleDir(appId);
    if (await dir.exists()) await dir.delete(recursive: true);
    _cache.remove(appId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Directory> _bundleDir(String appId) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/$_bundlesDir/$appId');
    await dir.create(recursive: true);
    return dir;
  }

  Future<bool> _hasIndex(Directory dir) async {
    return File('${dir.path}/index.html').exists();
  }

  /// Copies all asset files for a built-in bundle to [dir].
  Future<void> _extractAssetBundle(String appId, Directory dir) async {
    final prefix = 'assets/mini_apps/$appId-bundle';
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = assetManifest
        .listAssets()
        .where((k) => k.startsWith(prefix))
        .toList();

    for (final assetKey in keys) {
      // Relative path inside the bundle dir, e.g. "css/style.css"
      final relative = assetKey.substring('$prefix/'.length);
      final outFile = File('${dir.path}/$relative');
      await outFile.create(recursive: true);
      final data = await rootBundle.load(assetKey);
      await outFile.writeAsBytes(data.buffer.asUint8List());
    }
  }
}
