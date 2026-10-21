import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LiveLocationRepository {
  Future<void> upsertMyLocation({required double lat, required double lng, required DateTime expiresAt});
  Future<void> stopSharing();

  /// 自己目前還有效的分享到期時間，沒在分享就回傳 null。
  /// App 重開後用來恢復「分享中」狀態——伺服器上的位置在到期前都還是公開的。
  Future<DateTime?> fetchMySharingUntil();

  /// 目前有效分享中的其他人位置（RLS 已限制 expires_at > now()，這裡不用再篩）。
  Future<List<Map<String, dynamic>>> fetchActiveLiveLocations();
}

class SupabaseLiveLocationRepository implements LiveLocationRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<void> upsertMyLocation({required double lat, required double lng, required DateTime expiresAt}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('尚未登入，無法分享位置');
    await _supabase.from('live_locations').upsert({
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    });
  }

  @override
  Future<void> stopSharing() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase.from('live_locations').delete().eq('user_id', userId);
  }

  @override
  Future<DateTime?> fetchMySharingUntil() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _supabase.from('live_locations').select('expires_at').eq('user_id', userId).maybeSingle();
    if (row == null) return null;
    return DateTime.parse(row['expires_at'] as String).toLocal();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchActiveLiveLocations() async {
    final response = await _supabase.from('live_locations').select('*, profiles(display_name)');
    return List<Map<String, dynamic>>.from(response);
  }
}
