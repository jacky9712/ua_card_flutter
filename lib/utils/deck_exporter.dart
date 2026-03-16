// lib/utils/deck_exporter.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ua_card.dart';
import '../screens/deck_export_widget.dart';

class DeckExporter {
  // 用來在畫面上方顯示載入圈圈
  static final GlobalKey<State> _loaderKey = GlobalKey<State>();

  static Future<void> exportAndShareDeck({
    required BuildContext context,
    required Map<int, int> deckMap,
    required List<UACard> allCards,
  }) async {
    // 0. 防呆：牌組是空的就不要匯出
    if (deckMap.isEmpty) return;

    // 1. 顯示載入中對話框 (截圖需要一點時間)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          key: _loaderKey,
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("正在產生牌組圖片..."),
              ],
            ),
          ),
        );
      },
    );

    // 2. 建立一個 ScreenshotController
    final screenshotController = ScreenshotController();

    try {
      // 3. 實例化我們的匯出 Widget，但**不要把這行貼上網**。
      final exportWidget = Material( // 必須包在 Material 裡面，否則文字樣式會跑版
          child: DeckExportWidget(deckMap: deckMap, allCards: allCards)
      );

      // 4. 🔥 最魔法的一行：在記憶體中偷偷渲染這個 Widget 並捕捉成圖片
      // 使用 invisibleWidget 可以在不打斷玩家的情況下在背景完成截圖
      final imageBytes = await screenshotController.captureFromWidget(
        exportWidget,
        // 如果卡片很多，這裡需要給足夠的渲染時間讓圖片下載完成
        delay: const Duration(seconds: 2),
        pixelRatio: 2.0, // 調高解析度
      );

      // 5. 隱藏載入對話框
      if (_loaderKey.currentContext != null) {
        Navigator.of(_loaderKey.currentContext!, rootNavigator: true).pop();
      }

      // 6. 將圖片 Bytes 存成臨時檔案
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/ua_deck_share.png').create();
      await file.writeAsBytes(imageBytes);

      // 7. 🔥 呼叫原生分享選單，把檔案分享出去
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '這是我剛用 UA Card App 組好的牌組，強吧！',
        subject: 'UA 牌組分享', // iOS 用的郵件主旨
      );

    } catch (e) {
      // 錯誤處理
      if (_loaderKey.currentContext != null) {
        Navigator.of(_loaderKey.currentContext!, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯出失敗: $e')),
      );
    }
  }
}