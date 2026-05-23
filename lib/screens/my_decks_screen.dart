// lib/screens/my_decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../viewmodels/card_view_model.dart';
import 'deck_detail_screen.dart';

class MyDecksScreen extends ConsumerStatefulWidget {
  const MyDecksScreen({super.key});

  @override
  ConsumerState<MyDecksScreen> createState() => _MyDecksScreenState();
}

class _MyDecksScreenState extends ConsumerState<MyDecksScreen> {
  @override
  void initState() {
    super.initState();
    // 進入畫面時，非同步自動去 Supabase 撈取使用者的所有雲端牌組
    Future.microtask(() => ref.read(cardViewModelProvider.notifier).fetchMyDecks());
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(cardViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141419), // 對齊 Kadoraba 的深色底
      appBar: AppBar(
        title: const Text('我的牌組', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uiState.isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700))))
          : uiState.myDecks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: uiState.myDecks.length,
        itemBuilder: (context, index) {
          final deck = uiState.myDecks[index];
          final seriesName = deck['series'] != null ? deck['series']['name_zh'] : '未知系列';
          final seriesCode = deck['series'] != null ? (deck['series']['series_code'] as String).toUpperCase() : '';
          final String? coverUrl = deck['cover_card_url'];

          // 解析時間
          final date = DateTime.parse(deck['created_at']);
          final dateString = DateFormat('yyyy/MM/dd').format(date);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C2C35), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // 🖼️ 左側：Kadoraba 風格的卡片縮圖封面
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 44,
                  height: 60,
                  color: const Color(0xFF2C2C35),
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (context, url, error) => const Icon(Icons.style, color: Colors.amber, size: 20),
                  )
                      : const Icon(Icons.style, color: Colors.amber, size: 20),
                ),
              ),
              // 📝 中間：牌組名稱與系列代碼
              title: Text(
                  deck['name'] ?? '未命名牌組',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[$seriesCode] $seriesName',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('建立時間: $dateString', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),

              // 🚀 核心點擊導航：轉圈圈並撈取 50 張卡片傳送到詳情頁
              onTap: () async {
                // 1. 彈出防誤觸的 Loading 轉圈
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700))),
                  ),
                );

                final int deckId = deck['id'] as int;
                // 2. 呼叫我們剛剛在 ViewModel 裡寫好的 fetchCardsForDeck 方法
                final cards = await ref.read(cardViewModelProvider.notifier).fetchCardsForDeck(deckId);

                // 3. 關閉 Loading 轉圈
                if (context.mounted) Navigator.pop(context);

                // 4. 成功拿到 50 張卡片後，直接挺進 Kadoraba 圖表詳情頁！
                if (cards.isNotEmpty) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeckDetailScreen(
                          deckName: deck['name'] ?? '未命名牌組',
                          cardsInDeck: cards,
                        ),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🚨 無法讀取該牌組內容，或牌組內無卡片！'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  // 當雲端沒有半套牌組時的華麗空白提示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey.shade800),
          const SizedBox(height: 16),
          const Text('目前雲端還沒有儲存任何牌組', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('立刻去組一套', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}