import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';

class MatchRecordState {
  final List<Map<String, dynamic>> records;
  final bool isLoading;
  final String? errorMessage;

  MatchRecordState({this.records = const [], this.isLoading = false, this.errorMessage});

  MatchRecordState copyWith({List<Map<String, dynamic>>? records, bool? isLoading, String? errorMessage}) {
    return MatchRecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  int get totalCount => records.length;
  int get winCount => records.where((r) => r['result'] == 'win').length;
  int get lossCount => records.where((r) => r['result'] == 'loss').length;
  int get drawCount => records.where((r) => r['result'] == 'draw').length;

  double get winRate {
    // 平手不計入勝率的分母，只算「有分出勝負」的場次。
    final decided = winCount + lossCount;
    if (decided == 0) return 0;
    return winCount / decided * 100;
  }
}

class MatchRecordViewModel extends Notifier<MatchRecordState> {
  @override
  MatchRecordState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchMyMatchRecords);
    return MatchRecordState();
  }

  Future<void> fetchMyMatchRecords() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      final records = await repo.fetchMyMatchRecords();
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入戰績失敗');
    }
  }

  Future<bool> createMatchRecord({
    String? opponentId,
    String? opponentNameText,
    int? playerDeckId,
    String? deckNameSnapshot,
    String? deckTier,
    required String result,
    String? note,
    int? meetupPostId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      await repo.createMatchRecord(
        opponentId: opponentId,
        opponentNameText: opponentNameText,
        playerDeckId: playerDeckId,
        deckNameSnapshot: deckNameSnapshot,
        deckTier: deckTier,
        result: result,
        note: note,
        meetupPostId: meetupPostId,
      );
      await fetchMyMatchRecords();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '紀錄失敗: $e');
      return false;
    }
  }

  Future<void> deleteMatchRecord(int id) async {
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      await repo.deleteMatchRecord(id);
      await fetchMyMatchRecords();
    } catch (e) {
      state = state.copyWith(errorMessage: '刪除失敗: $e');
    }
  }
}

final matchRecordViewModelProvider =
    NotifierProvider<MatchRecordViewModel, MatchRecordState>(() => MatchRecordViewModel());
