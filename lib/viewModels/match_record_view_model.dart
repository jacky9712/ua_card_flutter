import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';
import '../utils/match_record_stats.dart';

class MatchRecordState {
  final List<Map<String, dynamic>> records;
  final bool isLoading;
  final AppError? error;
  final String? myUserId;

  MatchRecordState({this.records = const [], this.isLoading = false, this.error, this.myUserId});

  MatchRecordState copyWith({List<Map<String, dynamic>>? records, bool? isLoading, AppError? error, String? myUserId}) {
    return MatchRecordState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      myUserId: myUserId ?? this.myUserId,
    );
  }

  int get totalCount => records.length;

  /// result 是從記錄者角度存的，統計一律換成「我」的角度（見 resultFromMyPerspective）。
  MatchStats get stats => matchStatsOf(records, myUserId);
  int get winCount => stats.win;
  int get lossCount => stats.loss;
  int get drawCount => stats.draw;
  double get winRate => stats.winRate;

  List<MatchStatsGroup> get statsByDeck => matchStatsByDeck(records, myUserId);
  List<MatchStatsGroup> get statsByOpponent => matchStatsByOpponent(records, myUserId);
}

class MatchRecordViewModel extends Notifier<MatchRecordState> {
  @override
  MatchRecordState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchMyMatchRecords);
    return MatchRecordState();
  }

  Future<void> fetchMyMatchRecords() async {
    state = state.copyWith(isLoading: true, error: state.error.clearedIf(AppErrorCode.loadMatchesFailed));
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      final records = await repo.fetchMyMatchRecords();
      final myUserId = ref.read(authRepositoryProvider).currentUser?.id;
      // 不走 copyWith：myUserId 可能是 null（已登出），copyWith 的 ?? 會留著上一個帳號的 id。
      state = MatchRecordState(
        records: records,
        myUserId: myUserId,
        error: state.error.clearedIf(AppErrorCode.loadMatchesFailed),
      );
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

  Future<bool> deleteMatchRecord(int id) async {
    try {
      final repo = ref.read(matchRecordRepositoryProvider);
      await repo.deleteMatchRecord(id);
    } catch (e) {
      state = state.copyWith(error: AppError(AppErrorCode.deleteFailed, detail: '$e'));
      return false;
    }
    await fetchMyMatchRecords();
    return true;
  }
}

final matchRecordViewModelProvider =
    NotifierProvider<MatchRecordViewModel, MatchRecordState>(() => MatchRecordViewModel());
