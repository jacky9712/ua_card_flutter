import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:flutter/material.dart';
import '../repositories/providers.dart';

class DeckState {
  final Map<int, int> deckMap;
  final Map<int, UACard> deckCardDetails;
  final List<Map<String, dynamic>> myDecks;
  final bool isLoading;
  final String? errorMessage;

  DeckState({
    this.deckMap = const {},
    this.deckCardDetails = const {},
    this.myDecks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get totalDeckCount => deckMap.values.fold(0, (sum, qty) => sum + qty);
  
  int get totalDeckPrice {
    int total = 0;
    deckMap.forEach((id, qty) {
      final card = deckCardDetails[id];
      if (card?.price != null) total += card!.price! * qty;
    });
    return total;
  }

  DeckState copyWith({
    Map<int, int>? deckMap,
    Map<int, UACard>? deckCardDetails,
    List<Map<String, dynamic>>? myDecks,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DeckState(
      deckMap: deckMap ?? this.deckMap,
      deckCardDetails: deckCardDetails ?? this.deckCardDetails,
      myDecks: myDecks ?? this.myDecks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DeckViewModel extends Notifier<DeckState> {
  @override
  DeckState build() {
    return DeckState();
  }

  void updateCardQuantity(UACard card, int delta) {
    final cardId = card.id!;
    final currentQty = state.deckMap[cardId] ?? 0;
    final newQty = (currentQty + delta).clamp(0, 4);

    final newDeckMap = Map<int, int>.from(state.deckMap);
    final newDetails = Map<int, UACard>.from(state.deckCardDetails);

    if (newQty == 0) {
      newDeckMap.remove(cardId);
      newDetails.remove(cardId);
    } else {
      newDeckMap[cardId] = newQty;
      newDetails[cardId] = card;
    }
    state = state.copyWith(deckMap: newDeckMap, deckCardDetails: newDetails);
  }

  Future<void> fetchMyDecks() async {
    state = state.copyWith(isLoading: true);
    final deckRepo = ref.read(deckRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    
    try {
      List<Map<String, dynamic>> remoteDecks = [];
      if (user != null && user.appMetadata['provider'] != 'anonymous') {
        remoteDecks = await deckRepo.fetchRemoteDecks(user.id);
      }

      final localDecks = await deckRepo.fetchLocalDecks();
      state = state.copyWith(myDecks: [...localDecks, ...remoteDecks], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入牌組失敗');
    }
  }

  Future<bool> saveCurrentDeck(String deckName) async {
    if (state.totalDeckCount != 50) {
      state = state.copyWith(errorMessage: '🚨 儲存失敗：牌組必須剛好 50 張！');
      return false;
    }

    final deckRepo = ref.read(deckRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    final bool isRealUser = user != null && user.appMetadata['provider'] != 'anonymous';

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      int? detectedSeriesId;
      String? coverCardUrl;
      if (state.deckMap.isNotEmpty) {
        final firstCard = state.deckCardDetails.values.first;
        detectedSeriesId = firstCard.seriesId;
        coverCardUrl = firstCard.imageUrl;
      }

      if (!isRealUser) {
        // 🔥 本地儲存
        final List<Map<String, dynamic>> localCards = [];
        state.deckMap.forEach((id, qty) {
          final c = state.deckCardDetails[id]!;
          localCards.add({
            'quantity': qty,
            'card_data': {
              'id': c.id, 'card_number': c.cardNumber, 'name': c.name, 
              'image_url': c.imageUrl, 'color': c.color, 'energy_req': c.energyReq,
              'trigger_text': c.triggerText, 'price': c.price, 'series_id': c.seriesId,
            }
          });
        });

        await deckRepo.saveLocalDeck({
          'name': deckName, 'series_id': detectedSeriesId,
          'cover_card_url': coverCardUrl, 'cards': localCards,
        });
      } else {
        // 🔥 雲端儲存
        final List<Map<String, dynamic>> cardsJson = [];
        state.deckMap.forEach((id, qty) => cardsJson.add({'card_id': id, 'quantity': qty}));

        await deckRepo.saveRemoteDeck(
          name: deckName,
          seriesId: detectedSeriesId,
          coverCardUrl: coverCardUrl,
          cards: cardsJson,
        );
      }

      state = state.copyWith(isLoading: false, deckMap: {}, deckCardDetails: {});
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '儲存失敗: $e');
      return false;
    }
  }

  Future<bool> deleteDeck(int deckId) async {
    final deckRepo = ref.read(deckRepositoryProvider);
    try {
      if (deckId < 0) {
        await deckRepo.deleteLocalDeck(deckId);
      } else {
        await deckRepo.deleteRemoteDeck(deckId);
      }
      fetchMyDecks();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<List<UACard>> fetchCardsForDeck(int deckId) async {
    final deckRepo = ref.read(deckRepositoryProvider);
    try {
      if (deckId < 0) {
        final deck = state.myDecks.firstWhere((d) => d['id'] == deckId);
        final List<dynamic> cards = deck['cards'] ?? [];
        final List<UACard> expanded = [];
        for (var item in cards) {
          final cardData = item['card_data'];
          final card = UACard(
            id: cardData['id'], cardNumber: cardData['card_number'],
            name: cardData['name'], imageUrl: cardData['image_url'],
            color: cardData['color'], energyReq: cardData['energy_req'],
            triggerText: cardData['trigger_text'], price: cardData['price'],
            seriesId: cardData['series_id'],
          );
          for (int i = 0; i < item['quantity']; i++) expanded.add(card);
        }
        return expanded;
      }
      return await deckRepo.fetchRemoteDeckCards(deckId);
    } catch (e) {
      debugPrint('🚨 撈取牌組詳細卡片失敗: $e');
      return [];
    }
  }
}

final deckViewModelProvider = NotifierProvider<DeckViewModel, DeckState>(() => DeckViewModel());
