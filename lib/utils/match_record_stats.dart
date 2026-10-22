// lib/utils/match_record_stats.dart
// 對戰紀錄的戰績統計（總計 / 依牌組 / 依對手），純 Dart，畫面與 ViewModel 共用。

/// match_records 的 result 是從「記錄的那個人（player）」的角度存的。
/// 如果我是 opponent（別人幫我記的），要把結果反過來看才是「我」的勝敗。
/// [myUserId] 為 null 時不反轉（當成我是 player）。
String resultFromMyPerspective(Map<String, dynamic> record, String? myUserId) {
  final String result = record['result'];
  if (myUserId == null || record['player_id'] == myUserId) return result;
  switch (result) {
    case 'win':
      return 'loss';
    case 'loss':
      return 'win';
    default:
      return 'draw';
  }
}

class MatchStats {
  final int win;
  final int loss;
  final int draw;

  const MatchStats({this.win = 0, this.loss = 0, this.draw = 0});

  int get total => win + loss + draw;

  double get winRate {
    // 平手不計入勝率的分母，只算「有分出勝負」的場次。
    final decided = win + loss;
    if (decided == 0) return 0;
    return win / decided * 100;
  }
}

MatchStats matchStatsOf(Iterable<Map<String, dynamic>> records, String? myUserId) {
  final builder = _GroupBuilder(0);
  for (final record in records) {
    builder.add(resultFromMyPerspective(record, myUserId));
  }
  return builder.stats;
}

class MatchStatsGroup {
  final String key;

  /// null 代表畫面要換成 l10n 的「未指定」或 unnamedPlayer。
  final String? label;
  final MatchStats stats;

  const MatchStatsGroup({required this.key, required this.label, required this.stats});
}

/// 依牌組統計：只算我自己記的紀錄（別人記我的那筆沒有我的牌組資訊）。
List<MatchStatsGroup> matchStatsByDeck(List<Map<String, dynamic>> records, String? myUserId) {
  if (myUserId == null) return const [];
  final groups = <String, _GroupBuilder>{};
  for (final record in records) {
    if (record['player_id'] != myUserId) continue;
    final deckName = ((record['deck_name_snapshot'] as String?) ?? '').trim();
    groups
        .putIfAbsent(deckName, () => _GroupBuilder(groups.length))
        .add(resultFromMyPerspective(record, myUserId), label: deckName.isEmpty ? null : deckName);
  }
  return _toSortedGroups(groups);
}

/// 依對手統計：兩邊的紀錄都算。有帳號的對手以 user id 合併，自行輸入名字的以名字合併；
/// key 加前綴避免帳號 id 跟文字名字撞在一起。
List<MatchStatsGroup> matchStatsByOpponent(List<Map<String, dynamic>> records, String? myUserId) {
  if (myUserId == null) return const [];
  final groups = <String, _GroupBuilder>{};
  for (final record in records) {
    final String key;
    final String? label;
    if (record['player_id'] == myUserId) {
      final opponentId = record['opponent_id'];
      if (opponentId != null) {
        key = 'user:$opponentId';
        label = record['opponent_profile']?['display_name'] as String?;
      } else {
        final name = ((record['opponent_name_text'] as String?) ?? '').trim();
        key = 'name:$name';
        label = name.isEmpty ? null : name;
      }
    } else {
      key = 'user:${record['player_id']}';
      label = record['player_profile']?['display_name'] as String?;
    }
    groups
        .putIfAbsent(key, () => _GroupBuilder(groups.length))
        .add(resultFromMyPerspective(record, myUserId), label: label);
  }
  return _toSortedGroups(groups);
}

List<MatchStatsGroup> _toSortedGroups(Map<String, _GroupBuilder> groups) {
  final entries = groups.entries.toList()
    ..sort((a, b) {
      final at = a.value.total, bt = b.value.total;
      // List.sort 不保證穩定，同場次時用第一次出現的順序當第二排序鍵。
      return bt != at ? bt - at : a.value.order - b.value.order;
    });
  return [
    for (final e in entries) MatchStatsGroup(key: e.key, label: e.value.label, stats: e.value.stats),
  ];
}

class _GroupBuilder {
  _GroupBuilder(this.order);

  final int order;
  String? label;
  int win = 0;
  int loss = 0;
  int draw = 0;

  int get total => win + loss + draw;

  MatchStats get stats => MatchStats(win: win, loss: loss, draw: draw);

  void add(String result, {String? label}) {
    if (this.label == null && label != null) this.label = label;
    switch (result) {
      case 'win':
        win++;
      case 'loss':
        loss++;
      default:
        draw++;
    }
  }
}
