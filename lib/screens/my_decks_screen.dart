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
      backgroundColor: isDarkMode ? const Color(0xFF141419) : const Color(0xFFF8F9FA),
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
                    final bool isLocal = deck['id'] < 0;

                    return Card(
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
                          final expandedCards = await ref.read(deckViewModelProvider.notifier).fetchCardsForDeck(deck['id']);
                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DeckDetailScreen(
                              deckName: deck['name'],
                              cardsInDeck: expandedCards,
                            )));
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
