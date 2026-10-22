import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/deck_share_code_repository.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class DeckShareCodeState {
  final DeckShareCode? shareCode;
  final bool isLoading;
  final AppError? error;

  const DeckShareCodeState({this.shareCode, this.isLoading = false, this.error});
}

class DeckShareCodeViewModel extends Notifier<DeckShareCodeState> {
  @override
  DeckShareCodeState build() => const DeckShareCodeState();

  /// 用牌組字串向伺服器要一組新的分享代碼；失敗時錯誤進 state.error。
  Future<void> generate(String deckString) async {
    state = DeckShareCodeState(shareCode: state.shareCode, isLoading: true);
    try {
      final result = await ref.read(deckShareCodeRepositoryProvider).createShareCode(deckString);
      // await 期間畫面可能已經關掉、provider 被 autoDispose，之後就不能再碰 state。
      if (!ref.mounted) return;
      state = DeckShareCodeState(shareCode: result);
    } on DeckShareCodeRateLimitedException {
      if (!ref.mounted) return;
      state = const DeckShareCodeState(error: AppError(AppErrorCode.shareCodeRateLimited));
    } catch (e) {
      if (!ref.mounted) return;
      state = DeckShareCodeState(error: AppError(AppErrorCode.createShareCodeFailed, detail: '$e'));
    }
  }
}

/// autoDispose：離開牌組詳情頁就丟掉，下次進來不會殘留舊代碼。
final deckShareCodeViewModelProvider =
    NotifierProvider.autoDispose<DeckShareCodeViewModel, DeckShareCodeState>(DeckShareCodeViewModel.new);
