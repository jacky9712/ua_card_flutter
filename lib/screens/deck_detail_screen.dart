// lib/screens/deck_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/ua_card.dart';
import '../utils/deck_exporter.dart';

class DeckDetailScreen extends StatefulWidget {
  final String deckName;
  final List<UACard> cardsInDeck; // 50張展開的卡片
  final VoidCallback? onSavePressed;

  const DeckDetailScreen({
    super.key,
    required this.deckName,
    required this.cardsInDeck,
    this.onSavePressed,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  int _activeTabIndex = 0; // 0: 圖像, 1: 文字/QR

  Map<int, int> _getDeckMap() {
    final Map<int, int> map = {};
    for (var card in widget.cardsInDeck) {
      if (card.id != null) {
        map[card.id!] = (map[card.id!] ?? 0) + 1;
      }
    }
    return map;
  }

  String _generateDeckData() {
    final Map<int, int> deckMap = _getDeckMap();
    final List<String> parts = [];
    final List<UACard> uniqueCards = widget.cardsInDeck.toSet().toList();
    
    deckMap.forEach((cardId, quantity) {
      try {
        final card = uniqueCards.firstWhere((c) => c.id == cardId);
        parts.add('${card.cardNumber}:$quantity');
      } catch (_) {}
    });
    return 'UA_DECK|${parts.join(',')}';
  }

  // 🧮 數據處理：將 50 張卡片按卡號分組，用於顯示卡表
  Map<String, Map<String, dynamic>> _getGroupedCards() {
    final Map<String, Map<String, dynamic>> grouped = {};
    for (var card in widget.cardsInDeck) {
      if (!grouped.containsKey(card.cardNumber)) {
        grouped[card.cardNumber] = {
          'card': card,
          'count': 1,
        };
      } else {
        grouped[card.cardNumber]!['count']++;
      }
    }
    return grouped;
  }

  // 🧮 統計功能一：計算必要能源 分佈
  Map<int, int> _calculateEnergyDistribution() {
    final Map<int, int> dist = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (var card in widget.cardsInDeck) {
      final req = card.energyReq ?? 0;
      if (req >= 6) {
        dist[6] = (dist[6] ?? 0) + 1;
      } else {
        dist[req] = (dist[req] ?? 0) + 1;
      }
    }
    return dist;
  }

  // 🧮 統計功能二：觸發分佈 (精準識別 UA 各顏色 Color Trigger)
  Map<String, int> _calculateTriggerDistribution() {
    final Map<String, int> dist = {
      'SPECIAL': 0, 'COLOR': 0, 'FINAL': 0, 'DRAW': 0,
      'GET': 0, 'ACTIVE': 0, 'RAID': 0, 'OTHER': 0, 'NONE': 0
    };
    for (var card in widget.cardsInDeck) {
      final text = card.triggerText?.trim() ?? '';
      
      if (text.isEmpty || text == '-') {
        dist['NONE'] = dist['NONE']! + 1;
        continue;
      }

      // 1. 優先判定 COLOR (使用您提供的精準描述)
      if (text.contains('カラー') || text.contains('COLOR') ||
          text.contains('BP2500以下の相手') || // 紅色 Color
          text.contains('BP3500以下の相手') || // 藍色 Color
          (text.contains('レストにする') && text.contains('アクティブにならない')) || // 黃色 Color
          (text.contains('2以下') && text.contains('消費APが1') && text.contains('登場させる'))) { // 綠/紫 Color
        dist['COLOR'] = dist['COLOR']! + 1;
      }
      // 2. 判定 RAID (截圖中的重要類別)
      else if (text.contains('レイド') || text.contains('RAID')) {
        dist['RAID'] = dist['RAID']! + 1;
      }
      // 3. 判定 SPECIAL (排除掉已認定的 Color)
      else if (text.contains('スペシャル') || text.contains('SPECIAL') || text.contains('退場させる')) {
        dist['SPECIAL'] = dist['SPECIAL']! + 1;
      }
      // 4. 其餘標準觸發
      else if (text.contains('アクティブ') || text.contains('ACTIVE')) {
        dist['ACTIVE'] = dist['ACTIVE']! + 1;
      }
      else if (text.contains('手札に加える') || text.contains('ゲット') || text.contains('GET')) {
        dist['GET'] = dist['GET']! + 1;
      }
      else if (text.contains('1枚引く') || text.contains('ドロー') || text.contains('DRAW')) {
        dist['DRAW'] = dist['DRAW']! + 1;
      }
      else if (text.contains('ファイナル') || text.contains('FINAL') || text.contains('自分のライフエリアに置く')) {
        dist['FINAL'] = dist['FINAL']! + 1;
      }
      else {
        dist['OTHER'] = dist['OTHER']! + 1;
      }
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final groupedCards = _getGroupedCards();
    final energyData = _calculateEnergyDistribution();
    final triggerData = _calculateTriggerDistribution();
    final maxEnergyCount = energyData.values.reduce((a, b) => a > b ? a : b);
    final int totalPrice = widget.cardsInDeck.fold(0, (sum, card) => sum + (card.price ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF141419),
      appBar: AppBar(
        title: Text(widget.onSavePressed != null ? '儲存前預覽' : widget.deckName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 20),
            onPressed: () {
              DeckExporter.exportAndShareDeck(
                context: context,
                deckMap: _getDeckMap(),
                allCards: widget.cardsInDeck.toSet().toList(),
              );
            },
          )
        ],
      ),
      bottomNavigationBar: widget.onSavePressed != null 
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: widget.onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('儲存至我的牌組 (完成編輯)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          )
        : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            
            // 根據頁籤切換內容
            _activeTabIndex == 0 
                ? _buildCardImageGrid(groupedCards)
                : _buildTextAndQRSection(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeckHeaderOverview(totalPrice),
                  const SizedBox(height: 24),
                  const Text('成本分佈', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _buildEnergyChart(energyData, maxEnergyCount),
                  const SizedBox(height: 24),
                  const Text('觸發分佈', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  _buildTriggerGrid(triggerData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _tabItem('卡片圖像', 0),
          const SizedBox(width: 20),
          _tabItem('導入 QR', 1),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    bool isActive = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
          if (isActive) Container(margin: const EdgeInsets.only(top: 4), height: 2, width: 20, color: Colors.redAccent)
        ],
      ),
    );
  }

  Widget _buildTextAndQRSection() {
    final String deckData = _generateDeckData();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('牌組導入 QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: deckData,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          const Text('其他玩家掃描此碼即可快速導入您的牌組', 
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardImageGrid(Map<String, Map<String, dynamic>> groupedCards) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 0.68,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: groupedCards.length,
        itemBuilder: (context, index) {
          final item = groupedCards.values.elementAt(index);
          final UACard card = item['card'];
          final int count = item['count'];

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: card.imageUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade900),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Text('x$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeckHeaderOverview(int totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('總張數', style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 4),
              Text('50 枚', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('預估價格 (參考)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('¥ $totalPrice', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEnergyChart(Map<int, int> data, int maxVal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: data.entries.map((entry) {
          final barWidthRatio = maxVal > 0 ? (entry.value / maxVal) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 35,
                  child: Text('${entry.key == 6 ? '6+' : entry.key} 能', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 16, decoration: BoxDecoration(color: const Color(0xFF2C2C35), borderRadius: BorderRadius.circular(4))),
                      FractionallySizedBox(
                        widthFactor: barWidthRatio == 0 ? 0.02 : barWidthRatio,
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFCE93D8)]),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 25,
                  child: Text('${entry.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTriggerGrid(Map<String, int> data) {
    final triggerColors = {
      'SPECIAL': Colors.redAccent, 'COLOR': Colors.orangeAccent, 'FINAL': Colors.blueAccent,
      'DRAW': Colors.greenAccent, 'GET': Colors.yellowAccent, 'ACTIVE': Colors.cyanAccent,
      'RAID': Colors.pinkAccent, 'OTHER': Colors.blueGrey, 'NONE': Colors.grey,
    };

    // 依照截圖順序重新排序 key
    final sortedKeys = ['ACTIVE', 'GET', 'DRAW', 'RAID', 'COLOR', 'SPECIAL', 'FINAL'];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 配合截圖，改為 4 欄
          childAspectRatio: 1.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final count = data[key] ?? 0;
          final color = triggerColors[key] ?? Colors.grey;

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(key, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text('$count 枚', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
