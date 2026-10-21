import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/utils/postgrest_filter.dart';

void main() {
  group('escapePostgrestIlikeValue', () {
    const cases = <String, String>{
      'a,b': 'a_b',
      '(x': '_x',
      'x)': 'x_',
      '100%': r'100\%',
      'a_b': r'a\_b',
      r'a\b': r'a\\b',
      'a*b': 'a_b',
      'a"b': 'a_b',
      '紫雲': '紫雲',
      '': '',
    };

    cases.forEach((input, expected) {
      test('「$input」→「$expected」', () {
        expect(escapePostgrestIlikeValue(input), expected);
      });
    });

    test('結果不含任何 PostgREST or-filter 結構字元', () {
      for (final input in cases.keys) {
        final result = escapePostgrestIlikeValue(input);
        expect(result, isNot(matches(RegExp(r'[,()"*]'))), reason: 'input: $input');
      }
    });
  });
}
