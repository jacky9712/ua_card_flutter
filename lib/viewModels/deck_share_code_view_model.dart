import 'package:flutter/foundation.dart';
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

  /// 打開分享分頁時呼叫：這副牌組已經有還沒過期的代碼就直接顯示，不用再按一次產生。
  /// 查詢失敗（例如沒網路）只記 log，不顯示錯誤，使用者照樣可以按產生。
  Future<void> loadExisting(String deckString) async {
    try {
      final existing = await ref.read(deckShareCodeRepositoryProvider).findMyShareCode(deckString);
      if (!ref.mounted) return;
      // 查詢途中使用者已經按了產生（或已經有結果），就不要蓋掉。
      if (existing == null || state.shareCode != null || state.isLoading) return;
      state = DeckShareCodeState(shareCode: existing, error: state.error);
    } catch (e) {
      debugPrint('查詢既有分享代碼失敗: $e');
    }
  }

  /// 用牌組字串向伺服器要分享代碼（有效期限內會拿回同一組）；失敗時錯誤進 state.error。
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
