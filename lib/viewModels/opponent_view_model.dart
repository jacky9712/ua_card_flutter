import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class OpponentState {
  final List<Map<String, dynamic>> knownOpponents;
  final bool isLoading;
  final AppError? error;

  OpponentState({this.knownOpponents = const [], this.isLoading = false, this.error});

  OpponentState copyWith({List<Map<String, dynamic>>? knownOpponents, bool? isLoading, AppError? error}) {
    return OpponentState(
      knownOpponents: knownOpponents ?? this.knownOpponents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OpponentViewModel extends Notifier<OpponentState> {
  @override
  OpponentState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchKnownOpponents);
    return OpponentState();
  }

  Future<void> fetchKnownOpponents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(opponentRepositoryProvider);
      final list = await repo.fetchKnownOpponents();
      state = state.copyWith(knownOpponents: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.loadOpponentsFailed));
    }
  }

  /// 解析 QR 掃到的字串（格式：`UA_PLAYER|` 後面接使用者 uuid），查對方 profile、加進已知對手清單。
  /// 回傳對方的顯示名稱（成功；對方沒設暱稱時是空字串，由畫面顯示翻譯後的「未命名玩家」）
  /// 或 null（失敗，錯誤會進 state.error）。
  Future<String?> addOpponentFromQr(String code) async {
    if (!code.startsWith('UA_PLAYER|')) {
      state = state.copyWith(error: const AppError(AppErrorCode.invalidQr));
      return null;
    }
    final opponentId = code.substring('UA_PLAYER|'.length).trim();
    if (opponentId.isEmpty) {
      state = state.copyWith(error: const AppError(AppErrorCode.invalidQr));
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.fetchProfile(opponentId);
      if (profile == null) {
        state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.playerNotFound));
        return null;
      }

      final opponentRepo = ref.read(opponentRepositoryProvider);
      await opponentRepo.addKnownOpponent(opponentId);
      await fetchKnownOpponents(); // 重新整理清單
      return (profile['display_name'] as String?) ?? '';
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.addOpponentFailed, detail: '$e'));
      return null;
    }
  }
}

final opponentViewModelProvider = NotifierProvider<OpponentViewModel, OpponentState>(() => OpponentViewModel());
