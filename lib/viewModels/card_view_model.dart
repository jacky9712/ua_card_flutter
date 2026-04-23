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
  final Map<int, UACard> deckCardDetails;

  // 🔥 新增：首頁對戰環境排行數據
  final List<Map<String, dynamic>> rankingList;

  CardState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.isLoading = true,
    this.searchQuery = '',
    this.deckMap = const {},
    this.availableSeries = const [],
    this.selectedSeries = '',
    this.deckCardDetails = const {},
    this.rankingList = const [], // 初始化
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
    List<Map<String, dynamic>>? rankingList,
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
      rankingList: rankingList ?? this.rankingList,
    );
  }

  int get totalDeckCount => deckMap.values.fold(0, (sum, quantity) => sum + quantity);

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

  // 🔥 整合初始化：同時抓取系列清單與排行數據
  Future<void> _initData() async {
    try {
      // 並行執行多個請求，加速啟動
      await Future.wait([
        _fetchSeriesList(),
        fetchRanking(), // 抓取首頁排行
      ]);

      // 接著預載首批卡片
      fetchCards();
    } catch (e) {
      print('初始化失敗: $e');
      fetchCards();
    }
  }

  Future<void> _fetchSeriesList() async {
    final response = await _supabase.from('series').select('series_code').order('id');
    final List<String> seriesList = response
        .map((s) => s['series_code'].toString().toUpperCase())
        .toList();
    state = state.copyWith(availableSeries: seriesList);
  }

  // 🔥 實作：從資料庫抓取排行數據
  // 假設你有一個 series_popularity 的 View 或直接算 deck_cards 的統計
  Future<void> fetchRanking() async {
    try {
      // 這裡暫時模擬抓取邏輯，若你已建立 View，請改成你的 View 名稱
      // final response = await _supabase.from('series_popularity').select().limit(5);

      // 這裡先放一點 Mock Data 讓首頁有東西顯示，你可以隨時接上真實 SQL
      final mockRanking = [
        {'rank': '#1', 'title': '[紫] 阿米婭 & 陳', 'share': '12.5%', 'count': '201'},
        {'rank': '#2', 'title': '[青] 凱爾希', 'share': '10.2%', 'count': '185'},
        {'rank': '#3', 'title': '[紅] 曉歌', 'share': '8.7%', 'count': '156'},
      ];

      state = state.copyWith(rankingList: mockRanking);
    } catch (e) {
      print('排行抓取失敗: $e');
    }
  }

  Future<void> fetchCards() async {
    state = state.copyWith(isLoading: true);
    try {
      var query = _supabase.from('cards').select('*, latest_prices(price_jpy)');
      if (state.selectedSeries.isNotEmpty) {
        query = query.ilike('card_number', '${state.selectedSeries}%');
      }
      final response = await query.order('card_number', ascending: true).limit(150);
      final cards = response.map((json) => UACard.fromJson(json)).toList();
      state = state.copyWith(allCards: cards, isLoading: false);
      _applyLocalSearch();
    } catch (e) {
      print('抓取失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

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
    if (query.length < 2 && query.isNotEmpty) {
      _applyLocalSearch();
      return;
    }
    _remoteSearch(query);
  }

  Future<void> _remoteSearch(String query) async {
    if (query.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final response = await _supabase
          .from('cards')
          .select('*, latest_prices(price_jpy)')
          .or('card_number.ilike.%$query%,name.ilike.%$query%')
          .order('card_number', ascending: true)
          .limit(100);
      final cards = response.map((json) => UACard.fromJson(json)).toList();
      state = state.copyWith(allCards: cards, filteredCards: cards, isLoading: false);
    } catch (e) {
      print('遠端搜尋失敗: $e');
      state = state.copyWith(isLoading: false);
    }
  }

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
      newDeckCardDetails.remove(cardId);
    } else {
      newDeckMap[cardId] = newQty;
      try {
        final card = state.allCards.firstWhere((c) => (c.id as num).toInt() == cardId);
        newDeckCardDetails[cardId] = card;
      } catch (e) {
        print("卡片不在當前列表中，無法更新詳情快取");
      }
    }
    state = state.copyWith(deckMap: newDeckMap, deckCardDetails: newDeckCardDetails);
  }
}

final cardViewModelProvider = NotifierProvider<CardViewModel, CardState>(() => CardViewModel());