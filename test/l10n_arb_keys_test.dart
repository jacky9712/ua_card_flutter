import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 繁中 app_zh.arb 是 template；新增字串時如果漏加到日文或英文，gen-l10n 只會
// 默默退回 template 的中文，畫面上看起來就是「怎麼這裡沒翻」。這裡直接擋下來。
Set<String> _messageKeys(String lang) {
  final json = jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  final zh = _messageKeys('zh');

  for (final lang in ['ja', 'en']) {
    test('app_$lang.arb 的 key 跟 app_zh.arb 完全一致', () {
      final other = _messageKeys(lang);
      expect(zh.difference(other), isEmpty, reason: 'app_$lang.arb 缺少這些 key');
      expect(other.difference(zh), isEmpty, reason: 'app_$lang.arb 多出 app_zh.arb 沒有的 key');
    });
  }
}
