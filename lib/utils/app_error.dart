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
  searchCardsFailed,
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
      AppErrorCode.searchCardsFailed => l10n.errSearchCardsFailed,
    };
    return detail == null ? message : l10n.errorWithDetail(message, detail!);
  }
}


extension AppErrorClear on AppError? {
  /// 只有目前的錯誤是 [code] 才清掉，其他錯誤原樣保留。
  ///
  /// 給清單載入用：載入只該清掉「上次載入失敗」這種自己的錯誤。使用者操作（掃 QR、發文、改暱稱…）
  /// 剛回報的錯誤要留給畫面顯示，不然 build() 排的初始載入晚一步跑完，就會把它蓋掉。
  AppError? clearedIf(AppErrorCode code) => this?.code == code ? null : this;
}
