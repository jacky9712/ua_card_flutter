import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/repositories/deck_share_code_repository.dart';

void main() {
  test('伺服器回 UA429 時轉成 DeckShareCodeRateLimitedException', () {
    final translated = translateShareCodeError(
      const PostgrestException(message: 'deck share code rate limit exceeded', code: 'UA429'),
    );
    expect(translated, isA<DeckShareCodeRateLimitedException>());
  });

  test('其他錯誤原樣丟回', () {
    const other = PostgrestException(message: 'could not allocate deck share code', code: '53400');
    expect(translateShareCodeError(other), same(other));

    final network = Exception('network down');
    expect(translateShareCodeError(network), same(network));
  });
}
