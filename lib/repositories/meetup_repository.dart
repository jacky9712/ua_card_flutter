import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MeetupRepository {
  /// 目前未過期的約戰貼文（RLS 已經限制 expires_at > now()，這裡不用再篩一次）。
  Future<List<Map<String, dynamic>>> fetchOpenMeetupPosts();

  Future<void> createMeetupPost({
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  });

  /// 只有貼文擁有者能改（RLS「Owner manages own meetup posts」擋）。
  /// [scheduledAt] 為 null 時不動 expires_at，避免把還沒到期的貼文改成馬上過期。
  Future<void> updateMeetupPost({
    required int id,
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  });

  Future<void> deleteMeetupPost(int id);

  /// 訂閱 meetup_posts 的新增/修改/刪除，有變動就呼叫 [onChange]。
  /// 回傳取消訂閱的函式。
  void Function() subscribeToChanges(void Function() onChange);
}

class SupabaseMeetupRepository implements MeetupRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchOpenMeetupPosts() async {
    final response = await _supabase
        .from('meetup_posts')
        .select('*, profiles(display_name)')
        .order('scheduled_at', ascending: true, nullsFirst: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> createMeetupPost({
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('尚未登入，無法發布約戰貼文');
    // 有排定時間的話，貼文的存活期跟著約定時間走（加 3 小時緩衝給約戰本身跑完），
    // 而不是固定 created_at + 24h——不然約明天的貼文可能今天就先過期消失，
    // 約下週的貼文卻在約定時間到之前就先被 24h 規則砍掉。沒排時間才用預設 24h。
    final expiresAt = scheduledAt?.add(const Duration(hours: 3));
    await _supabase.from('meetup_posts').insert({
      'user_id': userId,
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'note': note,
      'scheduled_at': scheduledAt?.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      // 本地（未同步）牌組是負數 id，不在 decks 表裡，deck_id 的外鍵會擋掉——
      // 那種情況只存快照名稱，deck_id 留空。
      'deck_id': (deckId != null && deckId > 0) ? deckId : null,
      'deck_name_snapshot': deckNameSnapshot,
      'deck_tier': deckTier,
    });
  }

  @override
  Future<void> updateMeetupPost({
    required int id,
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  }) async {
    final expiresAt = scheduledAt?.add(const Duration(hours: 3));
    await _supabase.from('meetup_posts').update({
      'location_name': locationName,
      'lat': lat,
      'lng': lng,
      'note': note,
      'scheduled_at': scheduledAt?.toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      'deck_id': (deckId != null && deckId > 0) ? deckId : null,
      'deck_name_snapshot': deckNameSnapshot,
      'deck_tier': deckTier,
    }).eq('id', id);
  }

  @override
  Future<void> deleteMeetupPost(int id) async {
    await _supabase.from('meetup_posts').delete().eq('id', id);
  }

  @override
  void Function() subscribeToChanges(void Function() onChange) {
    // 不直接用 payload 更新清單：清單需要 join profiles(display_name)，realtime payload 沒有，
    // 而且 RLS 開著時 DELETE 事件只帶主鍵。收到任何變動就整包重抓最單純也最不會錯。
    final channel = _supabase
        .channel('public:meetup_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'meetup_posts',
          callback: (_) => onChange(),
        )
        .subscribe();
    return () => _supabase.removeChannel(channel);
  }
}
