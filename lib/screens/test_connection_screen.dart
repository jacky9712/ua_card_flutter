// lib/screens/test_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewModels/card_library_view_model.dart';
import '../viewModels/deck_view_model.dart';
import '../models/ua_card.dart';
import 'card_detail_dialog.dart';
import 'deck_detail_screen.dart';

class TestConnectionScreen extends ConsumerStatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  ConsumerState<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends ConsumerState<TestConnectionScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(cardLibraryViewModelProvider).searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCardColor(String? colorStr) {
    switch (colorStr?.toUpperCase()) {
      case 'RED': return const Color(0xFFE53935);
      case 'BLUE': return const Color(0xFF1E88E5);
      case 'GREEN': return const Color(0xFF43A047);
      case 'YELLOW': return const Color(0xFFFFB300);
      case 'PURPLE': return const Color(0xFF8E24AA);
      default: return const Color(0xFF757575);
    }
  }

  void _navigateToPreview(DeckState deckState, bool isDarkMode) {
    final List<UACard> expandedCards = [];
    deckState.deckMap.forEach((cardId, quantity) {
      final card = deckState.deckCardDetails[cardId];
      if (card != null) {
        for (int i = 0; i < quantity; i++) {
          expandedCards.add(card);
        }
      }
    });

    Navigator.push(context, MaterialPageRoute(builder: (context) => DeckDetailScreen(
      deckName: '新牌組預覽',
      cardsInDeck: expandedCards,
      onSavePressed: () => _showSaveDialog(isDarkMode),
    )));
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(cardLibraryViewModelProvider);
    final deckState = ref.watch(deckViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color appBarColor = isDarkMode ? const Color(0xFF1E1E24) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF141419) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('組牌模式', style: TextStyle(fontWeight: FontWeight.w900, color: textColor, fontSize: 18)),
        backgroundColor: appBarColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: '搜尋卡號或名稱...',
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2C2C35) : const Color(0xFFEFEFF4),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(cardLibraryViewModelProvider.notifier).updateSearchQuery('');
                            },
                          )
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (text) => ref.read(cardLibraryViewModelProvider.notifier).updateSearchQuery(text),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showSeriesPicker(isDarkMode),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSettlement(deckState, isDarkMode),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), // 平滑過渡
        child: libraryState.isLoading 
            ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
            : libraryState.filteredCards.isEmpty
                ? const Center(key: ValueKey('empty'), child: Text('找不到符合的卡片'))
                : SizedBox.expand( // 強制填滿，避免高度變動
                    key: const ValueKey('grid_container'),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(10),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, 
                        childAspectRatio: 0.54, 
                        crossAxisSpacing: 8, 
                        mainAxisSpacing: 8
                      ),
                      itemCount: libraryState.filteredCards.length,
                      itemBuilder: (context, index) {
                        final card = libraryState.filteredCards[index];
                        final qty = deckState.deckMap[card.id] ?? 0;
                        return _buildCardItem(card, qty, isDarkMode);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildBottomSettlement(DeckState deckState, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white, 
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('目前張數: ${deckState.totalDeckCount} / 50', style: TextStyle(color: deckState.totalDeckCount > 50 ? Colors.red : Colors.grey)),
                Text('總金額: ¥ ${deckState.totalDeckPrice}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              ],
            ),
            ElevatedButton(
              onPressed: deckState.totalDeckCount == 50 ? () => _navigateToPreview(deckState, isDarkMode) : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('預覽並儲存'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(UACard card, int qty, bool isDarkMode) {
    final color = _getCardColor(card.color);
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: qty > 0 ? color : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InkWell(
                  onTap: () => showDialog(context: context, builder: (_) => CardDetailDialog(card: card)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: card.imageUrl ?? '', 
                      fit: BoxFit.contain,
                      // 🔥 加入佔位符確保高度穩定
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1))),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                if (qty > 0) Positioned(top: 0, left: 0, child: Container(padding: const EdgeInsets.all(4), color: color, child: Text('x$qty', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                
                // 💰 價格顯示
                if (card.price != null && card.price! > 0)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 0.8),
                      ),
                      child: Text(
                        '¥${card.price}',
                        style: const TextStyle(color: Color(0xFFFFE082), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 20), onPressed: qty > 0 ? () => ref.read(deckViewModelProvider.notifier).updateCardQuantity(card, -1) : null),
              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add, size: 20), onPressed: qty < 4 ? () => ref.read(deckViewModelProvider.notifier).updateCardQuantity(card, 1) : null),
            ],
          )
        ],
      ),
    );
  }

  void _showSeriesPicker(bool isDarkMode) {
    final libState = ref.read(cardLibraryViewModelProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2),
          itemCount: libState.availableSeries.length,
          itemBuilder: (ctx, i) {
            final series = libState.availableSeries[i];
            return ActionChip(
              label: Text(series), 
              onPressed: () {
                ref.read(cardLibraryViewModelProvider.notifier).updateSelectedSeries(series);
                Navigator.pop(ctx);
              }
            );
          },
        ),
      ),
    );
  }

  void _showSaveDialog(bool isDarkMode) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
      title: const Text('儲存牌組', style: TextStyle(fontWeight: FontWeight.bold)),
      content: TextField(
        controller: controller, 
        autofocus: true,
        decoration: const InputDecoration(hintText: '輸入牌組名稱...', border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            final deckName = controller.text.trim();
            if (deckName.isEmpty) return;

            // 1. 呼叫 ViewModel 執行儲存
            final success = await ref.read(deckViewModelProvider.notifier).saveCurrentDeck(deckName);
            
            if (success && mounted) {
              // 2. ✨ 核心修正：連退三步
              // 第一步：關閉對話框 (ctx)
              Navigator.pop(ctx); 
              
              // 第二步：關閉預覽頁面 (DeckDetailScreen)
              Navigator.pop(context); 
              
              // 第三步：關閉編輯頁面 (TestConnectionScreen)
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🎉 牌組「$deckName」儲存成功！'), backgroundColor: Colors.green),
              );
              
              // 3. 重新整理我的牌組列表
              ref.read(deckViewModelProvider.notifier).fetchMyDecks();
            }
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          child: const Text('確認儲存'),
        ),
      ],
    ));
  }
}
