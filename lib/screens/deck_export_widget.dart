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
    // 🔥 1. 改變資料整理方式：不再把重複的卡片拆開，而是綁定「卡片物件」與「數量」
    final List<MapEntry<UACard, int>> groupedCards = [];
    int totalCount = 0; // 計算總張數

    deckMap.forEach((cardId, quantity) {
      final card = allCards.firstWhere((c) => c.id == cardId);
      groupedCards.add(MapEntry(card, quantity));
      totalCount += quantity;
    });

    // 將卡片依照卡號排序，畫面更整齊
    groupedCards.sort((a, b) => a.key.cardNumber.compareTo(b.key.cardNumber));

    return Container(
      width: 1000,
      color: Colors.white,
      padding: const EdgeInsets.all(24.0), // 邊距稍微加寬一點點，比較有質感
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🏆 頂部標題區
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Union Arena 牌組分享',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(width: 16),
              Text(
                '總張數: $totalCount / 50',
                style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🃏 卡片網格 (現在只會渲染不重複的卡片)
          Wrap(
            spacing: 12, // 卡片水平間距
            runSpacing: 16, // 卡片垂直間距
            // 🔥 2. 把卡片和數量一起傳給 _buildCardItem
            children: groupedCards.map((entry) => _buildCardItem(entry.key, entry.value)).toList(),
          ),

          const SizedBox(height: 32),
          // 底部浮水印
          const Center(
            child: Text('Powered by UA Card Flutter', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // 🔥 3. 升級單張卡片的 Widget：接收 quantity 並加上數量標籤
  Widget _buildCardItem(UACard card, int quantity) {
    return SizedBox(
      width: 100, // 稍微放大一點點，因為不重複了，空間比較多
      child: Stack(
        clipBehavior: Clip.none, // 讓徽章可以稍微超出邊界一點點（看起來更立體）
        children: [
          // 🖼️ 底層：卡片圖片
          AspectRatio(
            aspectRatio: 0.7,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: card.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                  cacheKey: card.imageUrl,
                )
                    : Container(color: Colors.grey[300], child: const Icon(Icons.image_not_supported)),
              ),
            ),
          ),

          // 🏷️ 上層：右上角的數量徽章 (Badge)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.shade700, // 用顯眼的紅色標示數量
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2), // 加上白邊增加對比
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: Text(
                'x$quantity',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.0, // 確保文字置中
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}