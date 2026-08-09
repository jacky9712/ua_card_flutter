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
    // 「對戰環境」改回吃 series_popularity 這個 view——它是從真實玩家存的
    // decks/deck_cards 彙總出來的實際使用率，跟「上位卡組推薦」（torecards Tier表
    // 資料）是刻意分開的兩件事：一個是「大家實際在玩什麼」，一個是「環境上被
    // 認為強的牌組」，不應該混在一起顯示成同一份資料。
    final response = await _supabase.from('series_popularity').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
