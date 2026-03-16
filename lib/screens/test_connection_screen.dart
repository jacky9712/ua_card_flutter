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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
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
                    isDense: true,
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
                    itemCount: uiState.availableSeries.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final seriesValue = isAll ? '' : uiState.availableSeries[index - 1];
                      final displayLabel = isAll ? '全部系列' : seriesValue;
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

      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 讓高度剛好包住內容
              children: [
                Text(
                  '目前張數: ${uiState.totalDeckCount} / 50',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: uiState.totalDeckCount > 50 ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  // 顯示剛剛算好的總價
                  '總金額: ¥ ${uiState.totalDeckPrice}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber, // 用閃亮的金色
                  ),
                ),
              ],
            ),


            ElevatedButton.icon(
              onPressed: uiState.totalDeckCount > 0 ? () {
                DeckExporter.exportAndShareDeck(
                  context: context,
                  deckMap: uiState.deckMap,
                  allCards: uiState.allCards,
                );
              } : null,
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
            childAspectRatio: 0.52,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: uiState.filteredCards.length,
          itemBuilder: (context, index) {
            final card = uiState.filteredCards[index];
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
                  Expanded(
                    flex: 80,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => CardDetailDialog(card: card),
                        );
                      },
                      child: Column(
                        children: [
                          // 🖼️ 圖片區塊
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

                                // 左上角的數量標籤
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

                                if (card.price != null && card.price! > 0)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '¥${card.price}',
                                            style: const TextStyle(
                                              color: Colors.amberAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 📝 文字區塊
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

                  // 🎛️ 加減按鈕控制區
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