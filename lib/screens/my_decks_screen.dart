// lib/screens/my_decks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../viewmodels/deck_view_model.dart';
import 'deck_detail_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_theme.dart';

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

    return Scaffold(
      // 移除手動背景色，交給 MaterialApp 處理
      appBar: AppBar(
        title: Text(context.l10n.actionMyDecks, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: deckState.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : deckState.myDecks.isEmpty
              ? Center(child: Text(context.l10n.noDecksYet))
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
                            title: Text(context.l10n.confirmDelete),
                            content: Text(context.l10n.deleteDeckConfirm('${deck['name']}')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(context.l10n.delete, style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(deckViewModelProvider.notifier).deleteDeck(deckId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.deckDeleted('${deck['name']}'))),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.surface,
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
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.amber, width: 1),
                                      ),
                                      child: Icon(isLocal ? Icons.smartphone : Icons.cloud_done, color: Colors.amber, size: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          title: Text(deck['name'] ?? context.l10n.unnamedDeck, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(isLocal ? context.l10n.savedOnDevice : context.l10n.syncedToCloud, style: const TextStyle(fontSize: 12)),
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
