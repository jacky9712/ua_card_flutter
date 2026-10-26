import 'package:supabase_flutter/supabase_flutter.dart';

/// 伺服器產生的 6 位數牌組分享代碼與到期時間。
class DeckShareCode {
  const DeckShareCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// 同一個使用者一小時內產生太多代碼，伺服器拒絕（create_deck_share_code 丟 errcode 'UA429'）。
class DeckShareCodeRateLimitedException implements Exception {
  const DeckShareCodeRateLimitedException();
}

/// 把 RPC 丟出的例外轉成 App 看得懂的型別：速率限制轉成 [DeckShareCodeRateLimitedException]，其他原樣丟回。
Object translateShareCodeError(Object error) {
  if (error is PostgrestException && error.code == 'UA429') return const DeckShareCodeRateLimitedException();
  return error;
}

abstract class DeckShareCodeRepository {
  /// 用 `UA_DECK|...` 牌組字串向伺服器要一組 6 位數分享代碼（7 天有效）。
  /// 自己對同一副牌組已經有還沒過期的代碼時，伺服器會回傳那組，不另外產生新的。
  Future<DeckShareCode> createShareCode(String deckString);

  /// 查自己對這副牌組目前還有效的代碼；沒有就回傳 `null`。
  Future<DeckShareCode?> findMyShareCode(String deckString);
}

DeckShareCode _parseShareCodeRow(Map<String, dynamic> row) {
  return DeckShareCode(
    code: (row['code'] as String).trim(),
    expiresAt: DateTime.parse(row['expires_at'] as String).toLocal(),
  );
}

class SupabaseDeckShareCodeRepository implements DeckShareCodeRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<DeckShareCode> createShareCode(String deckString) async {
    final Object? result;
    try {
      result = await _supabase.rpc('create_deck_share_code', params: {'deck_string': deckString});
    } catch (e) {
      throw translateShareCodeError(e);
    }
    final rows = result as List;
    if (rows.isEmpty) throw StateError('create_deck_share_code returned no row');
    return _parseShareCodeRow(rows.first as Map<String, dynamic>);
  }

  @override
  Future<DeckShareCode?> findMyShareCode(String deckString) async {
    final result = await _supabase.rpc('find_my_deck_share_code', params: {'deck_string': deckString});
    final rows = result as List;
    if (rows.isEmpty) return null;
    return _parseShareCodeRow(rows.first as Map<String, dynamic>);
  }
}
