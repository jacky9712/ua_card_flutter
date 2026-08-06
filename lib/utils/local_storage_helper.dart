import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  // 🔥 改用 shared_preferences 而非 dart:io File + path_provider：
  // 後者在 Flutter Web 上沒有真正的檔案系統，getApplicationDocumentsDirectory()/
  // File 讀寫在瀏覽器環境會直接丟例外，導致訪客（匿名登入，一定走本地儲存路徑）
  // 在 Web 上存牌組永遠失敗。shared_preferences 在 Web 上是用 localStorage 實作，
  // 各平台都能正常運作。
  static const String _prefsKey = 'local_decks';

  static Future<List<Map<String, dynamic>>> getLocalDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contents = prefs.getString(_prefsKey);
      if (contents == null) return [];
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveDeckLocally(Map<String, dynamic> deckData) async {
    final decks = await getLocalDecks();
    // 給予一個本地唯一的 ID (負數以區別資料庫 ID)
    deckData['id'] = -(DateTime.now().millisecondsSinceEpoch % 1000000);
    deckData['created_at'] = DateTime.now().toIso8601String();
    deckData['is_local'] = true;

    decks.insert(0, deckData); // 新的排前面

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(decks));
  }

  static Future<void> deleteLocalDeck(int deckId) async {
    final decks = await getLocalDecks();
    decks.removeWhere((deck) => deck['id'] == deckId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(decks));
  }
}
