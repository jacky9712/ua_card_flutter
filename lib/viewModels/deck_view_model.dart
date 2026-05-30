import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:flutter/material.dart';
import '../repositories/providers.dart';
import 'auth_view_model.dart';

class DeckState {
  final Map<int, int> deckMap;
  final Map<int, UACard> deckCardDetails;
  final List<Map<String, dynamic>> myDecks;
  final bool isLoading;
  final String? errorMessage;
  final int? editingDeckId; // 🔥 追蹤目前正在編輯的牌組 ID

  DeckState({
    this.deckMap = const {},
    this.deckCardDetails = const {},
    this.myDecks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.editingDeckId,
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
    int? editingDeckId,
    bool clearEditingId = false, // 用於手動重置
  }) {
    return DeckState(
      deckMap: deckMap ?? this.deckMap,
      deckCardDetails: deckCardDetails ?? this.deckCardDetails,
      myDecks: myDecks ?? this.myDecks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      editingDeckId: clearEditingId ? null : (editingDeckId ?? this.editingDeckId),
    );
  }
}

class DeckViewModel extends Notifier<DeckState> {
  @override
  DeckState build() {
    // 監聽 Auth 狀態，一旦使用者更換，就重新整理牌組清單
    ref.listen(authViewModelProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        fetchMyDecks();
      }
    });
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

  // 🔥 修改：載入編輯時紀錄 ID (改為 int? 以相容預覽模式)
  void loadDeckForEditing(int? deckId, List<UACard> cards) {
    final Map<int, int> newMap = {};
    final Map<int, UACard> newDetails = {};
    for (var card in cards) {
      if (card.id != null) {
        newMap[card.id!] = (newMap[card.id!] ?? 0) + 1;
        newDetails[card.id!] = card;
      }
    }
    state = state.copyWith(
      deckMap: newMap,
      deckCardDetails: newDetails,
      editingDeckId: deckId,
    );
  }

  // 清空編輯狀態（例如手動點擊「新增牌組」時）
  void clearEditor() {
    state = state.copyWith(
      deckMap: {},
      deckCardDetails: {},
      clearEditingId: true,
    );
  }

  Future<void> fetchMyDecks() async {
    state = state.copyWith(isLoading: true);
    final deckRepo = ref.read(deckRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;
    
    try {
      List<Map<String, dynamic>> remoteDecks = [];
      if (user != null && !user.isAnonymous) {
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
    final bool isRealUser = user != null && !user.isAnonymous;

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // 1. 如果是「編輯舊牌組」，儲存前先刪除舊的 (或之後實作 Update RPC)
      if (state.editingDeckId != null) {
        await deleteDeck(state.editingDeckId!);
      }

      int? detectedSeriesId;
      String? coverCardUrl;
      if (state.deckMap.isNotEmpty) {
        final firstCard = state.deckCardDetails.values.first;
        detectedSeriesId = firstCard.seriesId;
        coverCardUrl = firstCard.imageUrl;
      }

      if (!isRealUser) {
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
        await deckRepo.saveLocalDeck({'name': deckName, 'series_id': detectedSeriesId, 'cover_card_url': coverCardUrl, 'cards': localCards});
      } else {
        final List<Map<String, dynamic>> cardsJson = [];
        state.deckMap.forEach((id, qty) => cardsJson.add({'card_id': id, 'quantity': qty}));
        await deckRepo.saveRemoteDeck(name: deckName, seriesId: detectedSeriesId, coverCardUrl: coverCardUrl, cards: cardsJson);
      }

      // 🔥 2. 關鍵：儲存後自動觸發重新整理
      await fetchMyDecks();

      // 3. 重置編輯器
      state = state.copyWith(isLoading: false, deckMap: {}, deckCardDetails: {}, clearEditingId: true);
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
      // 刪除後也自動重新整理
      await fetchMyDecks();
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
      return [];
    }
  }

  Future<bool> importDeckFromQR(String qrData) async {
    if (!qrData.startsWith('UA_DECK|')) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final String content = qrData.substring(8);
      final List<String> pairs = content.split(',');
      final Map<String, int> targetCounts = {};
      for (var pair in pairs) {
        final List<String> parts = pair.split(':');
        if (parts.length == 2) targetCounts[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
      final cardRepo = ref.read(cardRepositoryProvider);
      final List<UACard> cards = await cardRepo.fetchCardsByNumbers(targetCounts.keys.toList());
      final Map<int, int> newDeckMap = {};
      final Map<int, UACard> newDetails = {};
      final Set<String> processedNumbers = {};
      for (var card in cards) {
        if (processedNumbers.contains(card.cardNumber)) continue;
        final int? qty = targetCounts[card.cardNumber];
        if (card.id != null && qty != null && qty > 0) {
          newDeckMap[card.id!] = qty;
          newDetails[card.id!] = card;
          processedNumbers.add(card.cardNumber);
        }
      }
      state = state.copyWith(deckMap: newDeckMap, deckCardDetails: newDetails, isLoading: false, clearEditingId: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '導入失敗: $e');
      return false;
    }
  }
}

final deckViewModelProvider = NotifierProvider<DeckViewModel, DeckState>(() => DeckViewModel());
