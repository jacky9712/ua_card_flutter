import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageHelper {
  static const String _fileName = 'local_decks.json';

  static Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  static Future<List<Map<String, dynamic>>> getLocalDecks() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return [];
      }
      final String contents = await file.readAsString();
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
    
    final file = await _getLocalFile();
    await file.writeAsString(json.encode(decks));
  }

  static Future<void> deleteLocalDeck(int deckId) async {
    final decks = await getLocalDecks();
    decks.removeWhere((deck) => deck['id'] == deckId);
    final file = await _getLocalFile();
    await file.writeAsString(json.encode(decks));
  }
}
