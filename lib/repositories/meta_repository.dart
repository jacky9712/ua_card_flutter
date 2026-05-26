import 'package:supabase_flutter/supabase_flutter.dart';

abstract class MetaRepository {
  Future<List<Map<String, dynamic>>> fetchRanking({int limit = 5});
  Future<List<Map<String, dynamic>>> fetchEnvironmentData();
}

class SupabaseMetaRepository implements MetaRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> fetchRanking({int limit = 5}) async {
    final response = await _supabase.from('series_popularity').select().limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async {
    // 這裡可以接真實 API 或傳回目前的 Mock 資料
    return [
      {'name_zh': '咒術迴戰 第1彈', 'share_rate': 35.5, 'use_count': 142, 'color': '紫', 'trend': 'up'},
      {'name_zh': 'HUNTER×HUNTER 獵人', 'share_rate': 28.0, 'use_count': 112, 'color': '黃', 'trend': 'down'},
      {'name_zh': 'Code Geass 反叛的魯路修', 'share_rate': 15.2, 'use_count': 61, 'color': '青', 'trend': 'stable'},
      {'name_zh': '偶像大師 閃耀色彩', 'share_rate': 10.8, 'use_count': 43, 'color': '黃', 'trend': 'new'},
      {'name_zh': '鬼滅之刃', 'share_rate': 10.5, 'use_count': 42, 'color': '紅', 'trend': 'stable'},
    ];
  }
}
