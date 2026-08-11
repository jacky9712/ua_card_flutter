import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRepository {
  /// 讀取單一使用者的 profile；找不到（理論上不該發生，trigger 會自動建）回傳 null。
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// 批次讀取多個使用者的 profile，給對手清單/約戰貼文作者名稱這類需要顯示
  /// 多人名稱的畫面用，一次查完比逐一查快。
  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> userIds);

  Future<void> updateDisplayName(String displayName);
}

class SupabaseProfileRepository implements ProfileRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final response = await _supabase.from('profiles').select().inFilter('id', userIds);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('尚未登入，無法設定暱稱');
    // upsert：理論上 trigger 已經建過一筆空白的了，這裡用 upsert 是防呆
    // （例如舊帳號在這支 migration 上線前就存在、backfill 沒跑到之類的邊界狀況）。
    await _supabase.from('profiles').upsert({
      'id': userId,
      'display_name': displayName,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
