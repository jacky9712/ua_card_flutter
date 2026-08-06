import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModels/deck_view_model.dart';
import '../viewModels/recommended_deck_view_model.dart';
import 'deck_detail_screen.dart';
import 'test_connection_screen.dart';

class RecommendedDecksScreen extends ConsumerStatefulWidget {
  const RecommendedDecksScreen({super.key});

  @override
  ConsumerState<RecommendedDecksScreen> createState() => _RecommendedDecksScreenState();
}

class _RecommendedDecksScreenState extends ConsumerState<RecommendedDecksScreen> {
  int? _openingDeckId;

  // 對應來源網站的 "Tier1" / "Tier1.5" / "Tier2" ... 分級字串
  Color _tierColor(String tier) {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
    final double rank = match != null ? double.tryParse(match.group(1)!) ?? 99 : 99;
    if (rank <= 1) return const Color(0xFFE53935);
    if (rank <= 2) return const Color(0xFFFF9800);
    if (rank <= 3) return const Color(0xFF1E88E5);
    return Colors.grey;
  }

  Future<void> _openDeck(Map<String, dynamic> deck) async {
    final int deckId = deck['id'];
    setState(() => _openingDeckId = deckId);

    final cards = await ref.read(recommendedDeckViewModelProvider.notifier).fetchCardsForDeck(deckId);

    if (!mounted) return;
    setState(() => _openingDeckId = null);

    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('這組牌組尚未建立完整卡表')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(
          deckName: deck['name'] ?? '推薦牌組',
          cardsInDeck: cards,
          saveButtonLabel: '複製到組牌編輯器',
          onSavePressed: () {
            ref.read(deckViewModelProvider.notifier).loadCardsForNewDeck(cards);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TestConnectionScreen()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendedDeckViewModelProvider);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('上位卡組推薦', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(recommendedDeckViewModelProvider.notifier).fetchRecommendedDecks(),
        child: state.isLoading && state.decks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.decks.isEmpty
                ? ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('目前尚無推薦牌組', style: TextStyle(color: Colors.grey))),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.decks.length,
                    itemBuilder: (context, index) {
                      final deck = state.decks[index];
                      final String tier = (deck['tier'] ?? '').toString();
                      // 圓形徽章空間有限，"Tier1.5" 這種字串只取數字部分顯示
                      final tierMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(tier);
                      final String tierBadge = tierMatch?.group(1) ?? '?';
                      final String seriesName = deck['series']?['name_zh'] ?? '未分類系列';
                      final winRate = deck['win_rate'];
                      final int totalPrice = deck['total_price'] ?? 0;
                      final int deckId = deck['id'];
                      final bool opening = _openingDeckId == deckId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: opening ? null : () => _openDeck(deck),
                          leading: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _tierColor(tier).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              tierBadge,
                              style: TextStyle(color: _tierColor(tier), fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ),
                          title: Text(deck['name'] ?? '未命名牌組', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '$seriesName'
                            '${tier.isNotEmpty ? ' · $tier' : ''}'
                            '${winRate != null ? ' · 勝率 $winRate%' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: opening
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '¥ $totalPrice',
                                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
