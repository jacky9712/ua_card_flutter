import '../l10n/app_localizations.dart';

/// ViewModel 回報給畫面的錯誤。ViewModel 拿不到 BuildContext、不能直接產生翻譯後的文字，
/// 所以只存錯誤代碼，由畫面用 [localize] 依目前語言轉成訊息。
enum AppErrorCode {
  authFailed,
  signOutFailed,
  dbConnectionFailed,
  loadDecksFailed,
  deckMustBe50,
  saveDeckFailed,
  importDeckFailed,
  loadNearbyFailed,
  locationNotSupported,
  locationUnavailable,
  loadMatchesFailed,
  recordMatchFailed,
  deleteFailed,
  loadMeetupsFailed,
  locationFallbackToTime,
  publishFailed,
  loadOpponentsFailed,
  invalidQr,
  playerNotFound,
  addOpponentFailed,
  loadProfileFailed,
  updateNicknameFailed,
  loadTopDecksFailed,
}

class AppError {
  const AppError(this.code, {this.detail});

  final AppErrorCode code;

  /// 原始例外內容等技術細節，沒辦法翻譯，接在翻譯後的訊息後面方便回報問題。
  final String? detail;

  String localize(AppLocalizations l10n) {
    final message = switch (code) {
      AppErrorCode.authFailed => l10n.authFailed,
      AppErrorCode.signOutFailed => l10n.errSignOutFailed,
      AppErrorCode.dbConnectionFailed => l10n.errDbConnectionFailed,
      AppErrorCode.loadDecksFailed => l10n.errLoadDecksFailed,
      AppErrorCode.deckMustBe50 => l10n.errDeckMustBe50,
      AppErrorCode.saveDeckFailed => l10n.errSaveDeckFailed,
      AppErrorCode.importDeckFailed => l10n.errImportDeckFailed,
      AppErrorCode.loadNearbyFailed => l10n.errLoadNearbyFailed,
      AppErrorCode.locationNotSupported => l10n.errLocationNotSupported,
      AppErrorCode.locationUnavailable => l10n.locationUnavailable,
      AppErrorCode.loadMatchesFailed => l10n.errLoadMatchesFailed,
      AppErrorCode.recordMatchFailed => l10n.errRecordMatchFailed,
      AppErrorCode.deleteFailed => l10n.errDeleteFailed,
      AppErrorCode.loadMeetupsFailed => l10n.errLoadMeetupsFailed,
      AppErrorCode.locationFallbackToTime => l10n.errLocationFallbackToTime,
      AppErrorCode.publishFailed => l10n.errPublishFailed,
      AppErrorCode.loadOpponentsFailed => l10n.errLoadOpponentsFailed,
      AppErrorCode.invalidQr => l10n.errInvalidQr,
      AppErrorCode.playerNotFound => l10n.errPlayerNotFound,
      AppErrorCode.addOpponentFailed => l10n.addOpponentFailed,
      AppErrorCode.loadProfileFailed => l10n.errLoadProfileFailed,
      AppErrorCode.updateNicknameFailed => l10n.errUpdateNicknameFailed,
      AppErrorCode.loadTopDecksFailed => l10n.errLoadTopDecksFailed,
    };
    return detail == null ? message : l10n.errorWithDetail(message, detail!);
  }
}
