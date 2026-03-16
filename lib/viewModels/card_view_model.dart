import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardState {
  final List<UACard> allCards;
  final List<UACard> filteredCards;
  final bool isLoading;
  final String searchQuery;
  final Map<int, int> deckMap;

  // 🔥 1. 這裡必須宣告這兩個新的變數
  final List<String> availableSeries;
  final String selectedSeries;

  CardState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.isLoading = true,
    this.searchQuery = '',
    this.deckMap = const {},
    // 🔥 2. 建構子也要給預設值
    this.availableSeries = const [],
    this.selectedSeries = '',
  });

  CardState copyWith({
    List<UACard>? allCards,
    List<UACard>? filteredCards,
    bool? isLoading,
    String? searchQuery,
    Map<int, int>? deckMap,
    // 🔥 3. copyWith 也要接收這兩個參數
    List<String>? availableSeries,
    String? selectedSeries,
  }) {
    return CardState(
      allCards: allCards ?? this.allCards,
      filteredCards: filteredCards ?? this.filteredCards,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      deckMap: deckMap ?? this.deckMap,
      // 🔥 4. 把新值傳進去
      availableSeries: availableSeries ?? this.availableSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
    );
  }

  int get totalDeckCount {
    return deckMap.values.fold(0, (sum, quantity) => sum + quantity);
  }
}

class CardViewModel extends Notifier<CardState> {
  final _supabase = Supabase.instance.client;

  @override
  CardState build() {
    fetchCards();
    return CardState(isLoading: true);
  }

  Future<void> fetchCards() async {
    try {
      final response = await _supabase
          .from('cards')
          .select()
          .order('card_number', ascending: true)
          .limit(100); // 測試時可以抓多一點來看篩選效果

      final cards = response.map((json) => UACard.fromJson(json)).toList();

      // 🔥 萃取出所有不重複的系列名稱 (過濾掉 null)
      final seriesSet = cards
          .map((c) {
        final parts = c.cardNumber.split('-');
        return parts.isNotEmpty ? parts.first : '未分類';
      })
          .toSet()
          .toList();

      state = state.copyWith(
        allCards: cards,
        filteredCards: cards,
        availableSeries: seriesSet, // 存入可選系列
        isLoading: false,
      );
    } catch (e) {
      print('抓取失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // 🔥 統一的過濾邏輯：同時考慮「搜尋字串」與「選中系列」
  void _applyFilters() {
    final lowerQuery = state.searchQuery.toLowerCase();

    final filtered = state.allCards.where((card) {
      // 1. 判斷搜尋是否符合
      final nameMatch = card.cardNumber.toLowerCase().contains(lowerQuery) ||
          (card.name ?? '').toLowerCase().contains(lowerQuery);

      // 🔥 2. 即時切割這張卡的卡號，拿來跟選中的標籤比對
      final cardSeriesPrefix = card.cardNumber.split('-').first;
      final seriesMatch = state.selectedSeries.isEmpty ||
          cardSeriesPrefix == state.selectedSeries;

      return nameMatch && seriesMatch;
    }).toList();

    state = state.copyWith(filteredCards: filtered);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters(); // 觸發過濾
  }

  // 🔥 新增：更新選中的系列
  void updateSelectedSeries(String series) {
    state = state.copyWith(selectedSeries: series);
    _applyFilters(); // 觸發過濾
  }

  void updateCardQuantity(int cardId, int delta) {
    final currentQty = state.deckMap[cardId] ?? 0;
    final newQty = (currentQty + delta).clamp(0, 4);

    final newDeckMap = Map<int, int>.from(state.deckMap);
    if (newQty == 0) {
      newDeckMap.remove(cardId);
    } else {
      newDeckMap[cardId] = newQty;
    }

    state = state.copyWith(deckMap: newDeckMap);
  }
}

final cardViewModelProvider = NotifierProvider<CardViewModel, CardState>(() {
  return CardViewModel();
});