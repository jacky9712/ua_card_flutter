import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class MatchRecordState {
  final List<Map<String, dynamic>> records;
  final bool isLoading;
  final AppError? error;

  MatchRecordState({this.records = const [], this.isLoading = false, this.error});

  MatchRecordState copyWith({List<Map<String, dynamic>>? records, bool? isLoading, AppError? error}) {
    return MatchRecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      final records = await repo.fetchMyMatchRecords();
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.loadMatchesFailed));
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
    state = state.copyWith(isLoading: true, error: null);
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
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.recordMatchFailed, detail: '$e'));
      return false;
    }
  }

  Future<void> deleteMatchRecord(int id) async {
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      await repo.deleteMatchRecord(id);
      await fetchMyMatchRecords();
    } catch (e) {
      state = state.copyWith(error: AppError(AppErrorCode.deleteFailed, detail: '$e'));
    }
  }
}

final matchRecordViewModelProvider =
    NotifierProvider<MatchRecordViewModel, MatchRecordState>(() => MatchRecordViewModel());
