import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MatchRecordRepository {
  /// 自己身為 player 或 opponent 的所有對戰紀錄（join 對手 profile）。
  Future<List<Map<String, dynamic>>> fetchMyMatchRecords();

  /// opponentId 跟 opponentNameText 至少要給一個：opponentId 是「已知對手」（掃過 QR、
  /// 有真實帳號，對方也看得到這筆紀錄）；opponentNameText 是自行輸入的名字（沒有帳號
  /// 可以連，純粹自己記錄用，對方不會、也不能看到這筆）。
  Future<void> createMatchRecord({
    String? opponentId,
    String? opponentNameText,
    int? playerDeckId,
    String? deckNameSnapshot,
    String? deckTier,
    required String result, // 'win' | 'loss' | 'draw'
    String? note,
    int? meetupPostId,
  });

  Future<void> deleteMatchRecord(int id);
}

class SupabaseMatchRecordRepository implements MatchRecordRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchMyMatchRecords() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    // RLS 本來就只放行「我是 player」或「我是 opponent」的列，這裡用 or() 一次撈兩邊，
    // 這樣不管是我記的、還是對方把我記成對手的，都會出現在「我的戰績」裡。
    final response = await _supabase
        .from('match_records')
        .select('*, opponent_profile:profiles!match_records_opponent_id_fkey(display_name), '
            'player_profile:profiles!match_records_player_id_fkey(display_name)')
        .or('player_id.eq.$userId,opponent_id.eq.$userId')
        .order('played_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> createMatchRecord({
    String? opponentId,
    String? opponentNameText,
    int? playerDeckId,
    String? deckNameSnapshot,
    String? deckTier,
    required String result,
    String? note,
    int? meetupPostId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('尚未登入，無法紀錄對戰');
    if (userId == opponentId) throw Exception('不能把自己記為對手');
    if (opponentId == null && (opponentNameText == null || opponentNameText.trim().isEmpty)) {
      throw Exception('請選擇已知對手，或至少輸入對手名字');
    }

    await _supabase.from('match_records').insert({
      'player_id': userId,
      'opponent_id': opponentId,
      'opponent_name_text': opponentNameText?.trim(),
      // 本地（未同步）牌組是負數 id，不在 decks 表裡，外鍵會擋掉，那種情況只存快照名稱。
      'player_deck_id': (playerDeckId != null && playerDeckId > 0) ? playerDeckId : null,
      'deck_name_snapshot': deckNameSnapshot,
      'deck_tier': deckTier,
      'result': result,
      'note': note,
      'meetup_post_id': meetupPostId,
    });
  }

  @override
  Future<void> deleteMatchRecord(int id) async {
    await _supabase.from('match_records').delete().eq('id', id);
  }
}
