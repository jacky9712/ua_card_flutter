// lib/screens/test_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/deck_exporter.dart';
import '../viewmodels/card_view_model.dart';
import 'card_detail_dialog.dart';

class TestConnectionScreen extends ConsumerWidget {
  const TestConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(cardViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('組牌模式'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // 🔥 修改 PreferredSize 的高度，容納搜尋框 + 篩選列
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // 高度從 60 增加到 110
          child: Column(
            children: [
              // 🔍 搜尋框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '搜尋卡號或名稱...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true, // 讓搜尋框稍微扁一點
                  ),
                  onChanged: (text) => ref.read(cardViewModelProvider.notifier).updateSearchQuery(text),
                ),
              ),

              // 🏷️ 系列篩選列 (橫向滾動)
              if (uiState.availableSeries.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    // +1 是為了在最前面加上「全部」的選項
                    itemCount: uiState.availableSeries.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      // 如果是「全部」，值就是空字串；否則從陣列取值
                      final seriesValue = isAll ? '' : uiState.availableSeries[index - 1];
                      final displayLabel = isAll ? '全部系列' : seriesValue;

                      // 判斷目前這個標籤是否被選中
                      final isSelected = uiState.selectedSeries == seriesValue;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(displayLabel),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(cardViewModelProvider.notifier).updateSelectedSeries(seriesValue);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),

      // 🔥 新增：底部統計與匯出列
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '目前張數: ${uiState.totalDeckCount} / 50',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: uiState.totalDeckCount > 50 ? Colors.red : Colors.black,
              ),
            ),
            // 🔥 修改點：更新按鈕的 onPressed
            ElevatedButton.icon(
              onPressed: uiState.totalDeckCount > 0 ? () {
                // 🔥 呼叫一鍵匯出與分享
                DeckExporter.exportAndShareDeck(
                  context: context,
                  deckMap: uiState.deckMap,
                  allCards: uiState.allCards,
                );
              } : null, // 沒卡片時按鈕禁用
              icon: const Icon(Icons.share),
              label: const Text('匯出牌組'),
            ),
          ],
        ),
      ),

      body: uiState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : uiState.filteredCards.isEmpty
          ? const Center(child: Text('找不到符合的卡片'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.52, // 🔥 把比例改小 (拉長)，騰出空間放按鈕
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: uiState.filteredCards.length,
          itemBuilder: (context, index) {
            final card = uiState.filteredCards[index];
            // 取得這張卡目前的選取數量 (找不到就是 0)
            final quantity = uiState.deckMap[card.id] ?? 0;

            return Card(
              elevation: quantity > 0 ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: quantity > 0 ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 🔥 修改點：把上面的 80% 空間 (圖片+文字) 包裝在一起，並加入 InkWell 點擊事件
                  Expanded(
                    flex: 80,
                    child: InkWell(
                      onTap: () {
                        // 點擊後彈出詳細資料 Dialog
                        showDialog(
                          context: context,
                          builder: (context) => CardDetailDialog(card: card),
                        );
                      },
                      child: Column(
                        children: [
                          // 🖼️ 圖片區塊 (改佔這 80% 裡面的 3 份)
                          Expanded(
                            flex: 3,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                card.imageUrl != null && card.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: card.imageUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                                )
                                    : const Icon(Icons.image_not_supported),

                                if (quantity > 0)
                                  Positioned(
                                    top: 0, left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8)),
                                      ),
                                      child: Text('x$quantity', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 📝 文字區塊 (改佔這 80% 裡面的 1 份)
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(fit: BoxFit.scaleDown, child: Text(card.cardNumber, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                                  FittedBox(fit: BoxFit.scaleDown, child: Text(card.name ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🎛️ 加減按鈕控制區 (維持在最底部的 20%，這裡的點擊不會觸發 Dialog)
                  Expanded(
                    flex: 20,
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: quantity > 0 ? () => ref.read(cardViewModelProvider.notifier).updateCardQuantity(card.id!, -1) : null,
                          ),
                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                            onPressed: quantity < 4 ? () => ref.read(cardViewModelProvider.notifier).updateCardQuantity(card.id!, 1) : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}