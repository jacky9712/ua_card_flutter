import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/test_connection_screen.dart';
import 'package:flutter/material.dart';
import '../screens/test_connection_screen.dart';
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
      // 抓取我們之前在 Supabase 建立的 series_popularity View
      final response = await _supabase
          .from('series_popularity')
          .select()
          .limit(5); // 只顯示前 5 名

      final list = List<Map<String, dynamic>>.from(response);
      state = state.copyWith(rankingList: list);
    } catch (e) {
      print('載入排行失敗: $e');
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

  void updateSearchQuery(String query, {BuildContext? context}) {
    state = state.copyWith(searchQuery: query);

    // 執行原本的搜尋邏輯
    _remoteSearch(query);

    // 🔥 優化：如果傳入了 context，代表在首頁輸入，自動跳轉到結果頁
    if (context != null && query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TestConnectionScreen()),
      );
    }
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

  Future<void> saveCurrentDeck(String deckName) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('請先登入！');
      return;
    }

    try {
      // 1. 插入牌組主表 (decks)
      // 這裡我們拿第一張卡的 series_id 當作牌組的系列
      final firstCardId = state.deckMap.keys.first;
      final seriesId = state.deckCardDetails[firstCardId]?.id;

      final deckResponse = await _supabase.from('decks').insert({
        'user_id': user.id,
        'name': deckName,
        'series_id': seriesId,
      }).select().single();

      final int deckId = deckResponse['id'];

      // 2. 準備牌組內容資料 (deck_cards)
      final List<Map<String, dynamic>> deckCardsData = [];
      state.deckMap.forEach((cardId, quantity) {
        deckCardsData.add({
          'deck_id': deckId,
          'card_id': cardId,
          'quantity': quantity,
        });
      });

      // 3. 批量插入牌組內容表
      await _supabase.from('deck_cards').insert(deckCardsData);

      print('牌組儲存成功！');
    } catch (e) {
      print('儲存失敗: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPriceHistory(int cardId) async {
    try {
      final response = await _supabase
          .from('price_history')
          .select('price_jpy, created_at')
          .eq('card_id', cardId)
          .order('created_at', ascending: true)
          .limit(30); // 抓最近 30 筆

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
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