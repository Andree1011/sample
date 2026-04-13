import 'package:flutter/material.dart';
import '../models/mini_app.dart';
import 'mini_app_card.dart';

class MiniAppGrid extends StatelessWidget {
  final List<MiniApp> apps;
  final void Function(MiniApp) onAppTap;

  const MiniAppGrid({
    super.key,
    required this.apps,
    required this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.apps, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No apps installed yet\nVisit the Marketplace to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final app = apps[index];
          return GestureDetector(
            onTap: () => onAppTap(app),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(app.colorValue),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(app.colorValue).withAlpha(80),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      app.emojiIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  app.name,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
        childCount: apps.length,
      ),
    );
  }
}
