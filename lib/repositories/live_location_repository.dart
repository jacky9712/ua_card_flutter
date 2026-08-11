import 'package:supabase_flutter/supabase_flutter.dart';

abstract class LiveLocationRepository {
  Future<void> upsertMyLocation({required double lat, required double lng, required DateTime expiresAt});
  Future<void> stopSharing();

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
  Future<List<Map<String, dynamic>>> fetchActiveLiveLocations() async {
    final response = await _supabase.from('live_locations').select('*, profiles(display_name)');
    return List<Map<String, dynamic>>.from(response);
  }
}
