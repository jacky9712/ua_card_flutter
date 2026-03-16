// lib/screens/deck_export_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ua_card.dart';

class DeckExportWidget extends StatelessWidget {
  final Map<int, int> deckMap;
  final List<UACard> allCards;

  const DeckExportWidget({
    super.key,
    required this.deckMap,
    required this.allCards,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 萃取出牌組裡所有的卡片物件，並整理成一個清單 (包含重複張數)
    final List<UACard> deckCards = [];
    deckMap.forEach((cardId, quantity) {
      final card = allCards.firstWhere((c) => c.id == cardId);
      for (int i = 0; i < quantity; i++) {
        deckCards.add(card);
      }
    });

    // 將卡片排序，匯出的圖片比較美觀
    deckCards.sort((a, b) => a.cardNumber.compareTo(b.cardNumber));

    // 2. 設計匯出圖片的排版 (例如固定 10 欄的網格)
    return Container(
      width: 1000, // 固定寬度，確保輸出的圖片解析度夠高
      color: Colors.white, // 白色背景
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // 根據內容自動伸縮高度
        children: [
          // 🏆 頂部標題
          const Text(
            'Union Arena 牌組分享',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(
            '總張數: ${deckCards.length} / 50',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 🃏 卡片網格 (不使用 GridView，用 Wrap 才能一次把所有卡片排出來不滾動)
          Wrap(
            spacing: 8, // 卡片水平間距
            runSpacing: 12, // 卡片垂直間距
            children: deckCards.map((card) => _buildCardItem(card)).toList(),
          ),

          const SizedBox(height: 20),
          // 底部浮水印
          const Center(
            child: Text('Powered by UA Card Flutter', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 製作單張卡片的小 Widget (只要圖片和簡單的數量即可)
  Widget _buildCardItem(UACard card) {
    return SizedBox(
      width: 90, // 固定單張卡片寬度，配合 1000 寬度大約可以排 10 張
      child: AspectRatio(
        aspectRatio: 0.7,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: card.imageUrl != null && card.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: card.imageUrl!,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 1)),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image),
            // 🔥 關鍵：圖片在截圖時必須已經下載完成
            cacheKey: card.imageUrl,
          )
              : const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }
}