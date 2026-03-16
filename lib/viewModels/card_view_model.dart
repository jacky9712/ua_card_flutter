import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CardState {
  final List<UACard> allCards;
  final List<UACard> filteredCards;
  final bool isLoading;
  final String searchQuery;
  final Map<int, int> deckMap;
  final List<String> availableSeries;
  final String selectedSeries;

  // 🔥 秘密武器：卡片快取記憶體
  // 當卡片被加入牌組時，把「卡片實體」存在這裡。
  // 這樣即使切換到別的系列，也能知道牌組裡的卡片價格是多少！
  final Map<int, UACard> deckCardDetails;

  CardState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.isLoading = true,
    this.searchQuery = '',
    this.deckMap = const {},
    this.availableSeries = const [],
    this.selectedSeries = '',
    this.deckCardDetails = const {}, // 初始化
  });

  CardState copyWith({
    List<UACard>? allCards,
    List<UACard>? filteredCards,
    bool? isLoading,
    String? searchQuery,
    Map<int, int>? deckMap,
    List<String>? availableSeries,
    String? selectedSeries,
    Map<int, UACard>? deckCardDetails,
  }) {
    return CardState(
      allCards: allCards ?? this.allCards,
      filteredCards: filteredCards ?? this.filteredCards,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      deckMap: deckMap ?? this.deckMap,
      availableSeries: availableSeries ?? this.availableSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
      deckCardDetails: deckCardDetails ?? this.deckCardDetails,
    );
  }

  // 計算總張數
  int get totalDeckCount {
    return deckMap.values.fold(0, (sum, quantity) => sum + quantity);
  }

  // 🔥 計算總金額 (從我們的秘密快取裡抓價格)
  int get totalDeckPrice {
    int totalPrice = 0;
    deckMap.forEach((cardId, quantity) {
      final card = deckCardDetails[cardId];
      if (card != null && card.price != null) {
        totalPrice += card.price! * quantity;
      }
    });
    return totalPrice;
  }
}

class CardViewModel extends Notifier<CardState> {
  final _supabase = Supabase.instance.client;

  @override
  CardState build() {
    _initData();
    return CardState(isLoading: true);
  }

  // 🔥 優化 1：初始化時，先去 series 資料表抓取「完整的」系列名單
  Future<void> _initData() async {
    try {
      final seriesResponse = await _supabase.from('series').select('series_code').order('id');

      // 取出 series_code (例如 cgh1, jjk1)，並轉成大寫作為標籤
      final List<String> seriesList = seriesResponse
          .map((s) => s['series_code'].toString().toUpperCase())
          .toList();

      state = state.copyWith(availableSeries: seriesList);

      // 接著抓取卡片
      fetchCards();
    } catch (e) {
      print('初始化系列失敗: $e');
      fetchCards();
    }
  }

  // 🔥 優化 2：伺服器端過濾
  // 現在不是把 8000 張全抓下來了，而是請 Supabase 幫我們過濾好再送過來
  Future<void> fetchCards() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. 建立基本查詢 (此時狀態是 FilterBuilder，可以加過濾條件)
      var query = _supabase
          .from('cards')
          .select('*, latest_prices(price_jpy)');

      // 2. 🔥 過濾條件必須在這裡先加！
      if (state.selectedSeries.isNotEmpty) {
        // 利用 ilike 尋找卡號開頭符合的
        query = query.ilike('card_number', '${state.selectedSeries}%');
      }

      // 3. 最後加上變形條件 (order, limit) 並執行 await
      final response = await query
          .order('card_number', ascending: true)
          .limit(150);

      final cards = response.map((json) => UACard.fromJson(json)).toList();

      state = state.copyWith(
        allCards: cards,
        isLoading: false,
      );

      // 觸發本地的字串搜尋過濾
      _applyLocalSearch();

    } catch (e) {
      print('抓取失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // 本地文字搜尋 (因為已經被 Supabase 縮小範圍了，本地搜尋會非常順暢)
  void _applyLocalSearch() {
    final lowerQuery = state.searchQuery.toLowerCase();

    if (lowerQuery.isEmpty) {
      state = state.copyWith(filteredCards: state.allCards);
      return;
    }

    final filtered = state.allCards.where((card) {
      return card.cardNumber.toLowerCase().contains(lowerQuery) ||
          (card.name ?? '').toLowerCase().contains(lowerQuery);
    }).toList();

    state = state.copyWith(filteredCards: filtered);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);

    // 🔥 如果關鍵字太短（例如只有 1 個字），就在本地搜就好，避免頻繁請求
    if (query.length < 2 && query.isNotEmpty) {
      _applyLocalSearch();
      return;
    }

    // 🔥 如果有輸入關鍵字，就直接發動遠端搜尋
    _remoteSearch(query);
  }

  Future<void> _remoteSearch(String query) async {
    state = state.copyWith(isLoading: true);
    try {
      var supabaseQuery = _supabase
          .from('cards')
          .select('*, latest_prices(price_jpy)');

      if (query.isNotEmpty) {
        // 同時搜尋卡號或名稱 (使用 or 語法)
        supabaseQuery = supabaseQuery.or('card_number.ilike.%$query%,name.ilike.%$query%');
      } else if (state.selectedSeries.isNotEmpty) {
        // 如果清空搜尋，就回歸目前選中的系列
        supabaseQuery = supabaseQuery.ilike('card_number', '${state.selectedSeries}%');
      }

      final response = await supabaseQuery.order('card_number', ascending: true).limit(100);
      final cards = response.map((json) => UACard.fromJson(json)).toList();

      state = state.copyWith(allCards: cards, filteredCards: cards, isLoading: false);
    } catch (e) {
      print('遠端搜尋失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  // 🔥 當玩家點擊上面的系列標籤時，觸發重新去資料庫抓資料
  void updateSelectedSeries(String series) {
    state = state.copyWith(selectedSeries: series, searchQuery: '');
    fetchCards();
  }

  void updateCardQuantity(int cardId, int delta) {
    final currentQty = state.deckMap[cardId] ?? 0;
    final newQty = (currentQty + delta).clamp(0, 4);

    final newDeckMap = Map<int, int>.from(state.deckMap);
    final newDeckCardDetails = Map<int, UACard>.from(state.deckCardDetails);

    if (newQty == 0) {
      newDeckMap.remove(cardId);
      newDeckCardDetails.remove(cardId); // 數量歸零，移出快取
    } else {
      newDeckMap[cardId] = newQty;

      // 🔥 關鍵步驟：把卡片存進快取
      // 因為 id 可能是字串，我們要轉型比對
      try {
        final card = state.allCards.firstWhere((c) => c.id == cardId);
        newDeckCardDetails[cardId] = card;
      } catch (e) {
        // 如果卡片已經在快取裡就略過
      }
    }

    state = state.copyWith(
      deckMap: newDeckMap,
      deckCardDetails: newDeckCardDetails,
    );
  }
}

final cardViewModelProvider = NotifierProvider<CardViewModel, CardState>(() {
  return CardViewModel();
});