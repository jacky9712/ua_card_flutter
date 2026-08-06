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

  // "Tier1" < "Tier1.5" < "Tier2" ... < "Tier6" 剛好是個位數，取數字部分來比大小排名
  // （跟 recommended_deck_repository.dart 的邏輯一致）。
  double _tierRank(String tier) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
    return match != null ? double.tryParse(match.group(1)!) ?? 99 : 99;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async {
    // 「對戰環境」現在直接從真實的「上位卡組推薦」資料回推：依系列彙總目前 Tier 表裡
    // 有幾組上位卡組、最好的 Tier 是多少，取代原本寫死的 Mock 數據。
    final response = await _supabase.from('recommended_decks').select('series_id, tier, series(name_zh)');

    final List<dynamic> rows = response;
    final Map<int, Map<String, dynamic>> bySeries = {};
    for (final row in rows) {
      final seriesId = row['series_id'];
      if (seriesId == null) continue;
      final tier = (row['tier'] ?? '').toString();

      final entry = bySeries.putIfAbsent(seriesId, () => {
            'name_zh': row['series']?['name_zh'] ?? '未知系列',
            'use_count': 0,
            'best_tier': tier,
          });
      entry['use_count'] = (entry['use_count'] as int) + 1;
      if (tier.isNotEmpty && _tierRank(tier) < _tierRank(entry['best_tier'] as String)) {
        entry['best_tier'] = tier;
      }
    }

    final totalDecks = rows.length;
    final list = bySeries.values.map((e) {
      final useCount = e['use_count'] as int;
      final shareRate = totalDecks > 0 ? (useCount / totalDecks * 100) : 0.0;
      return {
        'name_zh': e['name_zh'],
        'share_rate': double.parse(shareRate.toStringAsFixed(1)),
        'use_count': useCount,
        'best_tier': e['best_tier'],
      };
    }).toList();

    list.sort((a, b) {
      final tierCompare = _tierRank(a['best_tier']).compareTo(_tierRank(b['best_tier']));
      if (tierCompare != 0) return tierCompare;
      return (b['use_count'] as int).compareTo(a['use_count'] as int);
    });

    return list;
  }
}
