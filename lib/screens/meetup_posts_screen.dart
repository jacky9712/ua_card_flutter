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
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

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
        title: Text(context.l10n.cancelMeetupTitle),
        content: Text(context.l10n.cancelMeetupConfirm(locationName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l10n.keep)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.cancelPost, style: TextStyle(color: Colors.redAccent)),
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
    final posts = meetupState.sortedPosts;
    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.actionMeetup, style: TextStyle(fontWeight: FontWeight.bold)),
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
                Text(context.l10n.sortBy, style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(context.l10n.sortByTime),
                  selected: meetupState.sortMode == MeetupSortMode.soonest,
                  onSelected: (_) => ref.read(meetupViewModelProvider.notifier).setSortMode(MeetupSortMode.soonest),
                ),
                const SizedBox(width: 8),
                if (isLocationCapablePlatform)
                  ChoiceChip(
                    label: Text(context.l10n.sortByDistance),
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
                    ? Center(child: Text(context.l10n.noMeetups, style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () => ref.read(meetupViewModelProvider.notifier).fetchOpenMeetupPosts(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final authorName = post['profiles']?['display_name'] ?? context.l10n.unnamedPlayer;
                            final scheduledAt = DateTime.tryParse(post['scheduled_at'] ?? '');
                            final lat = post['lat'] as double?;
                            final lng = post['lng'] as double?;
                            final isOwner = myUserId != null && post['user_id'] == myUserId;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: AppColors.surface,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0x33FFC107),
                                  child: Icon(Icons.location_on, color: Colors.amber),
                                ),
                                title: Text(post['location_name'] ?? context.l10n.unnamedLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  [
                                    context.l10n.postedBy(authorName),
                                    if (scheduledAt != null) DateFormat('yyyy/MM/dd HH:mm').format(scheduledAt.toLocal()),
                                    if ((post['deck_name_snapshot'] as String?)?.isNotEmpty == true)
                                      context.l10n.deckWithName(
                                          '${post['deck_name_snapshot']}${(post['deck_tier'] as String?)?.isNotEmpty == true ? '(${post['deck_tier']})' : ''}'),
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
                                        tooltip: context.l10n.openMaps,
                                        onPressed: () => _openInMaps(context, lat, lng, post['location_name'] ?? ''),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.emoji_events_outlined),
                                      tooltip: context.l10n.recordRelatedMatch,
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
                                        tooltip: context.l10n.cancelPost,
                                        onPressed: () => _confirmDelete(
                                          context,
                                          ref,
                                          post['id'] as int,
                                          post['location_name'] ?? context.l10n.unnamedLocation,
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
