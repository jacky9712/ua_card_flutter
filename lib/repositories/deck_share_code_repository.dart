import 'package:supabase_flutter/supabase_flutter.dart';

/// 伺服器產生的 6 位數牌組分享代碼與到期時間。
class DeckShareCode {
  const DeckShareCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

abstract class DeckShareCodeRepository {
  /// 用 `UA_DECK|...` 牌組字串向伺服器要一組新的 6 位數分享代碼（24 小時有效）。
  Future<DeckShareCode> createShareCode(String deckString);
}

class SupabaseDeckShareCodeRepository implements DeckShareCodeRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<DeckShareCode> createShareCode(String deckString) async {
    final result = await _supabase.rpc('create_deck_share_code', params: {'deck_string': deckString});
    final rows = result as List;
    if (rows.isEmpty) throw StateError('create_deck_share_code returned no row');
    final row = rows.first as Map<String, dynamic>;
    return DeckShareCode(
      code: (row['code'] as String).trim(),
      expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
    );
  }
}
