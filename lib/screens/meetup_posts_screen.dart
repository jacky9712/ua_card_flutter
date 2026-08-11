// lib/screens/meetup_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewModels/meetup_view_model.dart';
import '../utils/location_platform.dart';
import 'create_match_record_screen.dart';
import 'create_meetup_post_screen.dart';

class MeetupPostsScreen extends ConsumerWidget {
  const MeetupPostsScreen({super.key});

  Future<void> _openInMaps(BuildContext context, double lat, double lng, String label) async {
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(label)})');
    final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, int postId, String locationName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消約戰貼文'),
        content: Text('確定要取消「$locationName」這則貼文嗎？取消後就不會再顯示。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('保留')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('取消貼文', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(meetupViewModelProvider.notifier).deleteMeetupPost(postId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetupState = ref.watch(meetupViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final posts = meetupState.sortedPosts;
    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('約戰地點', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMeetupPostScreen())),
        child: const Icon(Icons.add_location_alt, color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('排序：', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('最近時間'),
                  selected: meetupState.sortMode == MeetupSortMode.soonest,
                  onSelected: (_) => ref.read(meetupViewModelProvider.notifier).setSortMode(MeetupSortMode.soonest),
                ),
                const SizedBox(width: 8),
                if (isLocationCapablePlatform)
                  ChoiceChip(
                    label: const Text('最近距離'),
                    selected: meetupState.sortMode == MeetupSortMode.nearest,
                    onSelected: (_) => ref.read(meetupViewModelProvider.notifier).setSortMode(MeetupSortMode.nearest),
                  ),
              ],
            ),
          ),
          Expanded(
            child: meetupState.isLoading && posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                    ? const Center(child: Text('目前沒有約戰貼文', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(meetupViewModelProvider.notifier).fetchOpenMeetupPosts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final authorName = post['profiles']?['display_name'] ?? '（未命名玩家）';
                            final scheduledAt = DateTime.tryParse(post['scheduled_at'] ?? '');
                            final lat = post['lat'] as double?;
                            final lng = post['lng'] as double?;
                            final isOwner = myUserId != null && post['user_id'] == myUserId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0x33FFC107),
                                  child: Icon(Icons.location_on, color: Colors.amber),
                                ),
                                title: Text(post['location_name'] ?? '未命名地點', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  [
                                    '發布者: $authorName',
                                    if (scheduledAt != null) DateFormat('yyyy/MM/dd HH:mm').format(scheduledAt.toLocal()),
                                    if ((post['deck_name_snapshot'] as String?)?.isNotEmpty == true)
                                      '牌組: ${post['deck_name_snapshot']}'
                                          '${(post['deck_tier'] as String?)?.isNotEmpty == true ? '(${post['deck_tier']})' : ''}',
                                    if ((post['note'] as String?)?.isNotEmpty == true) post['note'],
                                  ].join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (lat != null && lng != null)
                                      IconButton(
                                        icon: const Icon(Icons.map_outlined),
                                        tooltip: '開啟地圖 App',
                                        onPressed: () => _openInMaps(context, lat, lng, post['location_name'] ?? ''),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.emoji_events_outlined),
                                      tooltip: '記錄與此相關的對戰',
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateMatchRecordScreen(initialMeetupPostId: post['id'] as int),
                                        ),
                                      ),
                                    ),
                                    if (isOwner)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        tooltip: '取消貼文',
                                        onPressed: () => _confirmDelete(
                                          context,
                                          ref,
                                          post['id'] as int,
                                          post['location_name'] ?? '未命名地點',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
