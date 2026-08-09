import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';

class OpponentState {
  final List<Map<String, dynamic>> knownOpponents;
  final bool isLoading;
  final String? errorMessage;

  OpponentState({this.knownOpponents = const [], this.isLoading = false, this.errorMessage});

  OpponentState copyWith({List<Map<String, dynamic>>? knownOpponents, bool? isLoading, String? errorMessage}) {
    return OpponentState(
      knownOpponents: knownOpponents ?? this.knownOpponents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(opponentRepositoryProvider);
      final list = await repo.fetchKnownOpponents();
      state = state.copyWith(knownOpponents: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入對手清單失敗');
    }
  }

  /// 解析 QR 掃到的字串（格式：`UA_PLAYER|` 後面接使用者 uuid），查對方 profile、加進已知對手清單。
  /// 回傳對方的顯示名稱（成功）或 null（失敗，錯誤訊息會進 state.errorMessage）。
  Future<String?> addOpponentFromQr(String code) async {
    if (!code.startsWith('UA_PLAYER|')) {
      state = state.copyWith(errorMessage: 'QR 格式不正確');
      return null;
    }
    final opponentId = code.substring('UA_PLAYER|'.length).trim();
    if (opponentId.isEmpty) {
      state = state.copyWith(errorMessage: 'QR 格式不正確');
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.fetchProfile(opponentId);
      if (profile == null) {
        state = state.copyWith(isLoading: false, errorMessage: '找不到這個玩家的資料');
        return null;
      }

      final opponentRepo = ref.read(opponentRepositoryProvider);
      await opponentRepo.addKnownOpponent(opponentId);
      await fetchKnownOpponents(); // 重新整理清單
      return (profile['display_name'] as String?) ?? '（未命名玩家）';
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '新增對手失敗: $e');
      return null;
    }
  }
}

final opponentViewModelProvider = NotifierProvider<OpponentViewModel, OpponentState>(() => OpponentViewModel());
