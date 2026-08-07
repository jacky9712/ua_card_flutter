// lib/screens/my_decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/deck_view_model.dart';
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
    Future.microtask(() => ref.read(deckViewModelProvider.notifier).fetchMyDecks());
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(deckViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: const Text('我的牌組', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: deckState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : deckState.myDecks.isEmpty
              ? const Center(child: Text('目前還沒有任何牌組，快去組一套吧！'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deckState.myDecks.length,
                  itemBuilder: (context, index) {
                    final deck = deckState.myDecks[index];
                    final int deckId = deck['id'];
                    final bool isLocal = deckId < 0;
                    final String? coverCardUrl = deck['cover_card_url'];

                    return Dismissible(
                      key: Key('deck_$deckId'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('確認刪除'),
                            content: Text('確定要刪除「${deck['name']}」嗎？'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('刪除', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(deckViewModelProvider.notifier).deleteDeck(deckId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已刪除牌組 ${deck['name']}')),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: coverCardUrl != null && coverCardUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: coverCardUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.amber.withValues(alpha: 0.1),
                                          ),
                                          // 圖片載入失敗就退回原本的本地/雲端圖示，不留空白
                                          errorWidget: (context, url, error) => Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.amber.withValues(alpha: 0.1),
                                            child: Icon(isLocal ? Icons.smartphone : Icons.cloud_done, color: Colors.amber),
                                          ),
                                        )
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.amber.withValues(alpha: 0.1),
                                          child: Icon(isLocal ? Icons.smartphone : Icons.cloud_done, color: Colors.amber),
                                        ),
                                ),
                                if (coverCardUrl != null && coverCardUrl.isNotEmpty)
                                  Positioned(
                                    bottom: -4,
                                    right: -4,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.amber, width: 1),
                                      ),
                                      child: Icon(isLocal ? Icons.smartphone : Icons.cloud_done, color: Colors.amber, size: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(deck['name'] ?? '未命名牌組', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isLocal ? '儲存於此裝置' : '已同步至雲端', style: const TextStyle(fontSize: 12)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥ ${deck['total_price'] ?? 0}',
                                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                          onTap: () async {
                            final expandedCards = await ref.read(deckViewModelProvider.notifier).fetchCardsForDeck(deckId);
                            if (context.mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => DeckDetailScreen(
                                deckId: deckId,
                                deckName: deck['name'],
                                cardsInDeck: expandedCards,
                              )));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
