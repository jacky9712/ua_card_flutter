import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:ua_card_flutter/main.dart';

void main() {
  testWidgets('設定讀不到時顯示錯誤畫面而不是空白', (tester) async {
    await tester.pumpWidget(const StartupErrorApp(locale: Locale('zh'), detail: 'SUPABASE_URL missing'));
    await tester.pumpAndSettle();

    expect(find.text('無法啟動 App'), findsOneWidget);
    expect(find.text('SUPABASE_URL missing'), findsOneWidget);
  });

  testWidgets('錯誤畫面跟著儲存的語言', (tester) async {
    await tester.pumpWidget(const StartupErrorApp(locale: Locale('ja'), detail: 'x'));
    await tester.pumpAndSettle();

    expect(find.text('アプリを起動できません'), findsOneWidget);
  });
}
