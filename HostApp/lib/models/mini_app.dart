class MiniApp {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String bundleUrl;
  final String version;
  final String category;
  bool isInstalled;
  final double rating;
  final int downloadCount;
  String? localBundlePath;

  MiniApp({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.bundleUrl,
    required this.version,
    required this.category,
    this.isInstalled = false,
    this.rating = 0.0,
    this.downloadCount = 0,
    this.localBundlePath,
  });

  factory MiniApp.fromJson(Map<String, dynamic> json) {
    return MiniApp(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String? ?? '',
      bundleUrl: json['bundle_url'] as String,
      version: json['version'] as String,
      category: json['category'] as String,
      isInstalled: json['is_installed'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      downloadCount: json['download_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon_url': iconUrl,
        'bundle_url': bundleUrl,
        'version': version,
        'category': category,
        'is_installed': isInstalled,
        'rating': rating,
        'download_count': downloadCount,
      };

  /// Returns an emoji icon for display when no image is available.
  String get emojiIcon {
    switch (id) {
      case 'shopping':
        return '🛍️';
      case 'health':
        return '❤️';
      case 'chat':
        return '💬';
      case 'food':
        return '🍔';
      case 'travel':
        return '✈️';
      case 'finance':
        return '💰';
      default:
        return '📱';
    }
  }

  /// Returns a color hex for the app icon background.
  int get colorValue {
    switch (id) {
      case 'shopping':
        return 0xFF6C63FF;
      case 'health':
        return 0xFFFF6B6B;
      case 'chat':
        return 0xFF4CAF50;
      case 'food':
        return 0xFFFF9800;
      case 'travel':
        return 0xFF2196F3;
      case 'finance':
        return 0xFF9C27B0;
      default:
        return 0xFF607D8B;
    }
  }
}
