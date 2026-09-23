import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/l10n/app_localizations.dart';
import 'package:ua_card_flutter/utils/app_error.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('錯誤代碼依語言翻譯', () {
    const error = AppError(AppErrorCode.playerNotFound);
    expect(error.localize(zh), '找不到這個玩家的資料');
    expect(error.localize(en), 'Player not found');
  });

  test('技術細節接在翻譯後的訊息後面，不翻譯', () {
    const error = AppError(AppErrorCode.saveDeckFailed, detail: 'SocketException: timeout');
    expect(error.localize(en), 'Save failed: SocketException: timeout');
  });

  test('每個錯誤代碼都有翻譯', () {
    for (final code in AppErrorCode.values) {
      expect(AppError(code).localize(en), isNotEmpty, reason: code.name);
    }
  });
}
