// lib/screens/my_decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(isLocal ? Icons.smartphone : Icons.cloud_done, color: Colors.amber),
                          ),
                          title: Text(deck['name'] ?? '未命名牌組', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isLocal ? '儲存於此裝置' : '已同步至雲端', style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
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
