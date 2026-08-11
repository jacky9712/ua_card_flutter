// lib/screens/live_location_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/location_platform.dart';
import '../viewModels/live_location_view_model.dart';

class LiveLocationScreen extends ConsumerWidget {
  const LiveLocationScreen({super.key});

  Future<void> _openInMaps(double lat, double lng, String label) async {
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})');
    final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('分享多久？', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final entry in {'30 分鐘': 30, '1 小時': 60, '2 小時': 120}.entries)
              ListTile(
                title: Text(entry.key),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await ref
                      .read(liveLocationViewModelProvider.notifier)
                      .startSharing(Duration(minutes: entry.value));
                  if (!context.mounted) return;
                  if (!success) {
                    final error = ref.read(liveLocationViewModelProvider).errorMessage ?? '分享失敗';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isLocationCapablePlatform) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            '此功能目前僅支援手機（Android / iOS）。桌面版的定位支援不穩定，先不開放。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final state = ref.watch(liveLocationViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final myUserId = Supabase.instance.client.auth.currentUser?.id;
    final others = state.nearbyOthers.where((o) => o['user_id'] != myUserId).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(liveLocationViewModelProvider.notifier).fetchNearbyOthers(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  state.isSharing ? Icons.location_on : Icons.location_off,
                  color: state.isSharing ? Colors.amber : Colors.grey,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  state.isSharing ? '分享中' : '目前沒有分享位置',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
                if (state.isSharing && state.sharingUntil != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '將於 ${state.sharingUntil!.hour.toString().padLeft(2, '0')}:'
                      '${state.sharingUntil!.minute.toString().padLeft(2, '0')} 自動停止',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: state.isSharing
                      ? OutlinedButton(
                          onPressed: () => ref.read(liveLocationViewModelProvider.notifier).stopSharing(),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                          child: const Text('停止分享'),
                        )
                      : ElevatedButton(
                          onPressed: state.isLoading ? null : () => _showDurationPicker(context, ref),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                          child: state.isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('分享我的位置'),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('目前分享中的玩家', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          if (others.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('目前沒有其他人在分享位置', style: TextStyle(color: Colors.grey))),
            )
          else
            ...others.map((o) {
              final name = o['profiles']?['display_name'] ?? '（未命名玩家）';
              final lat = o['lat'] as double?;
              final lng = o['lng'] as double?;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0x33FFC107), child: Icon(Icons.person, color: Colors.amber)),
                  title: Text(name),
                  trailing: (lat != null && lng != null)
                      ? IconButton(icon: const Icon(Icons.map_outlined), onPressed: () => _openInMaps(lat, lng, name))
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}
