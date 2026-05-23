// lib/screens/deck_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/ua_card.dart'; // 確保路徑正確

class DeckDetailScreen extends StatelessWidget {
  final String deckName;
  final List<UACard> cardsInDeck; // 傳入這套牌組裡包含的所有卡片（已展開數量，共50張）

  const DeckDetailScreen({
    super.key,
    required this.deckName,
    required this.cardsInDeck,
  });

  // 🧮 統計功能一：計算必要能源 (Energy Requirement) 分佈 (0 ~ 6+)
  Map<int, int> _calculateEnergyDistribution() {
    final Map<int, int> dist = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (var card in cardsInDeck) {
      final req = card.energyReq ?? 0;
      if (req >= 6) {
        dist[6] = (dist[6] ?? 0) + 1;
      } else {
        dist[req] = (dist[req] ?? 0) + 1;
      }
    }
    return dist;
  }

  // 🧮 統計功能二：根據資料庫 trigger_text 分類關鍵字 (Color, Special, Final...)
  Map<String, int> _calculateTriggerDistribution() {
    final Map<String, int> dist = {'SPECIAL': 0, 'COLOR': 0, 'FINAL': 0, 'DRAW': 0, 'OTHER': 0, 'NONE': 0};
    for (var card in cardsInDeck) {
      final text = card.triggerText?.toUpperCase() ?? '';
      if (text.isEmpty) {
        dist['NONE'] = dist['NONE']! + 1;
      } else if (text.contains('スペシャル') || text.contains('SPECIAL')) {
        dist['SPECIAL'] = dist['SPECIAL']! + 1;
      } else if (text.contains('カラートリガー') || text.contains('COLOR')) {
        dist['COLOR'] = dist['COLOR']! + 1;
      } else if (text.contains('ファイナルトリガー') || text.contains('FINAL')) {
        dist['FINAL'] = dist['FINAL']! + 1;
      } else if (text.contains('ドロー') || text.contains('DRAW')) {
        dist['DRAW'] = dist['DRAW']! + 1;
      } else {
        dist['OTHER'] = dist['OTHER']! + 1;
      }
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final energyData = _calculateEnergyDistribution();
    final triggerData = _calculateTriggerDistribution();

    // 找出能源數量的最大值，用來當作長條圖比例的基準分母
    final maxEnergyCount = energyData.values.reduce((a, b) => a > b ? a : b);
    final int totalPrice = cardsInDeck.fold(0, (sum, card) => sum + (card.price ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF141419), // 經典 Kadoraba 電競深色底
      appBar: AppBar(
        title: Text(deckName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💰 總價與張數看板
            _buildDeckHeaderOverview(totalPrice),
            const SizedBox(height: 20),

            // ⚡️ コスト分布 (必要能源分佈圖)
            const Text('コスト分布 (必要能源)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildEnergyChart(energyData, maxEnergyCount),

            const SizedBox(height: 24),

            // 🛡️ トリガー分布 (觸發分佈狀況)
            const Text('トリガー分布 (觸發特徵)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTriggerGrid(triggerData),
          ],
        ),
      ),
    );
  }

  // 頂部總覽小卡
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
              Text('カード總數', style: TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(height: 4),
              Text('50 枚', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('牌組估價 (Mercari)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('¥ $totalPrice', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          )
        ],
      ),
    );
  }

  // ⚡️ 橫向必要能源分佈圖 (完美還原 Kadoraba 直覺設計)
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
                      // 底槽
                      Container(height: 16, decoration: BoxDecoration(color: const Color(0xFF2C2C35), borderRadius: BorderRadius.circular(4))),
                      // 動態數據條
                      FractionallySizedBox(
                        widthFactor: barWidthRatio == 0 ? 0.02 : barWidthRatio, // 防呆留點微光
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFCE93D8)]), // 質感紫光
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

  // 🛡️ 觸發分佈矩陣 (Kadoraba 表格流線型呈現)
  Widget _buildTriggerGrid(Map<String, int> data) {
    final triggerColors = {
      'SPECIAL': Colors.redAccent,
      'COLOR': Colors.orangeAccent,
      'FINAL': Colors.blueAccent,
      'DRAW': Colors.greenAccent,
      'OTHER': Colors.blueGrey,
      'NONE': Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(8)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final key = data.keys.elementAt(index);
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