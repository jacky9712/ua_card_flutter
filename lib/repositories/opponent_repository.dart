import 'package:supabase_flutter/supabase_flutter.dart';

abstract class OpponentRepository {
  /// 已知對手清單（掃過 QR 認識的人），join profiles 拿顯示名稱。
  Future<List<Map<String, dynamic>>> fetchKnownOpponents();
  Future<void> addKnownOpponent(String opponentId, {String? nickname});
  Future<void> removeKnownOpponent(String opponentId);
}

class SupabaseOpponentRepository implements OpponentRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchKnownOpponents() async {
    // known_opponents 對 profiles 有兩條外鍵（owner_id、opponent_id），
    // 這裡一定要指名 known_opponents_opponent_id_fkey，不然 PostgREST 不知道要 join 哪一條。
    final response = await _supabase
        .from('known_opponents')
        .select('opponent_id, nickname, created_at, profiles!known_opponents_opponent_id_fkey(display_name)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> addKnownOpponent(String opponentId, {String? nickname}) async {
    final ownerId = _supabase.auth.currentUser?.id;
    if (ownerId == null) throw Exception('尚未登入，無法新增對手');
    if (ownerId == opponentId) throw Exception('不能把自己加為對手');
    await _supabase.from('known_opponents').upsert({
      'owner_id': ownerId,
      'opponent_id': opponentId,
      'nickname': ?nickname,
    }, onConflict: 'owner_id,opponent_id');
  }

  @override
  Future<void> removeKnownOpponent(String opponentId) async {
    final ownerId = _supabase.auth.currentUser?.id;
    if (ownerId == null) return;
    await _supabase.from('known_opponents').delete().eq('owner_id', ownerId).eq('opponent_id', opponentId);
  }
}
