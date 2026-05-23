import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/test_connection_screen.dart';
import 'package:flutter/material.dart';
class CardState {
  final List<UACard> allCards;
  final List<UACard> filteredCards;
  final bool isLoading;
  final String searchQuery;
  final Map<int, int> deckMap;
  final List<String> availableSeries;
  final String selectedSeries;
  final Map<int, UACard> deckCardDetails;

  // 首頁對戰環境排行數據
  final List<Map<String, dynamic>> rankingList;
  final String? errorMessage;
  final List<Map<String, dynamic>> metaData;
  //卡組用
  final List<Map<String, dynamic>> myDecks;

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
    this.errorMessage,
    this.metaData = const [],
    this.myDecks = const [],
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
    String? errorMessage,
    List<Map<String, dynamic>>? metaData,
    List<Map<String, dynamic>>? myDecks,
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
      errorMessage: errorMessage ?? this.errorMessage,
      metaData: metaData ?? this.metaData,
      myDecks: myDecks ?? this.myDecks,
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

  Future<void> fetchMyDecks() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true);

      // 多表關聯查詢：抓取牌組的同時，把所屬系列的中文名稱也順便 Select 出來
      final response = await _supabase
          .from('decks')
          .select('*, series(name_zh, series_code)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      state = state.copyWith(
        myDecks: List<Map<String, dynamic>>.from(response),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '抓取我的牌組失敗: $e');
    }
  }

  Future<void> fetchMetaEnvironment() async {
    try {
      // 直接撈取你寫好的 View
      final response = await _supabase
          .from('series_popularity')
          .select()
          .order('share_rate', ascending: false); // 依據市占率降冪排序

      //state = state.copyWith(metaData: List<Map<String, dynamic>>.from(response));

      state = state.copyWith(metaData: [
        {'name_zh': '咒術迴戰 第1彈', 'share_rate': 35.5, 'use_count': 142},
        {'name_zh': 'HUNTER×HUNTER 獵人', 'share_rate': 28.0, 'use_count': 112},
        {'name_zh': 'Code Geass 反叛的魯路修', 'share_rate': 15.2, 'use_count': 61},
        {'name_zh': '偶像大師 閃耀色彩', 'share_rate': 10.8, 'use_count': 43},
        {'name_zh': '鬼滅之刃', 'share_rate': 10.5, 'use_count': 42},
      ]);
    } catch (e) {
      // 這裡可以使用你之前設定的錯誤狀態或 logger
      state = state.copyWith(errorMessage: '無法載入對戰環境資料: $e');
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
    // 1. 初始化狀態，清空之前的錯誤訊息
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 2. 構建 Supabase 查詢
      // 這裡的 '*, latest_prices(price_jpy)' 會自動將卡片與最新價格關聯起來
      var query = _supabase.from('cards').select('''
      *,
      latest_prices(price_jpy)
    ''');

      // 3. 處理系列篩選 (例如：UA01BT)
      if (state.selectedSeries.isNotEmpty && state.selectedSeries != '全部系列') {
        query = query.ilike('card_number', '${state.selectedSeries}%');
      }

      // 4. 執行查詢並限制數量 (避免一次撈 8000 張記憶體爆炸)
      final response = await query
          .order('card_number', ascending: true)
          .limit(300);

      // 5. 安全地解析 JSON
      final List<UACard> parsedCards = [];

      for (var json in response) {
        try {
          parsedCards.add(UACard.fromJson(json));
        } catch (parseError) {
          // 🔥 如果有單張卡片欄位填錯，只會跳過那張，不會讓整個畫面死掉
          // 這裡因為 linter 規則，我們先註解 print，你可以用 logger 替換
          // print('跳過解析失敗的卡片: ${json['card_number']} - $parseError');
        }
      }

      // 6. 更新 UI 狀態
      state = state.copyWith(
        allCards: parsedCards,
        isLoading: false,
        // 🔥 暴力偵錯：如果撈出來是 0 筆，直接在畫面上印出提示
        errorMessage: parsedCards.isEmpty
            ? '資料庫連線成功，但裡面沒有卡片資料！(0 筆)\n請先執行 Python 爬蟲寫入資料。'
            : null,
      );

      // 重新套用本地的搜尋框關鍵字過濾
      _applyLocalSearch();

    } catch (e, stackTrace) {
      // 7. 捕捉網路或 Supabase RLS 被擋住的嚴重錯誤
      state = state.copyWith(
          isLoading: false,
          errorMessage: '🔥 資料庫請求崩潰啦：\n$e'
      );
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

    // 執行原本的搜尋邏輯
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

  Future<bool> saveCurrentDeck(String deckName) async {
    // 1. 檢查使用者登入狀態
    final user = _supabase.auth.currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: '🚨 儲存失敗：請先確認匿名登入（Anon Key）連線成功！');
      return false;
    }

    // 2. 前端基礎檢查（省下盲目發送請求的流量）
    if (state.totalDeckCount != 50) {
      state = state.copyWith(errorMessage: '🚨 儲存失敗：牌組必須剛好 50 張！(目前 ${state.totalDeckCount} 張)');
      return false;
    }

    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      // 3. 自動偵測系列與封面
      int? detectedSeriesId;
      String? coverCardUrl;
      if (state.deckMap.isNotEmpty) {
        try {
          final firstCardId = state.deckMap.keys.first;
          // 優先從 deckCardDetails 快取中找，如果沒有再從 allCards 找
          final firstCard = state.deckCardDetails[firstCardId] ?? 
                           state.allCards.firstWhere((c) => c.id == firstCardId);
          detectedSeriesId = firstCard.seriesId;
          coverCardUrl = firstCard.imageUrl;
        } catch (e) {
          debugPrint('自動偵測封面失敗: $e');
        }
      }

      // 4. 🔥 把牌組記憶體結構打包成標準後端要求的 JSON 陣列
      final List<Map<String, dynamic>> cardsJsonList = [];
      state.deckMap.forEach((cardId, quantity) {
        if (quantity > 0) {
          cardsJsonList.add({
            'card_id': cardId,
            'quantity': quantity,
          });
        }
      });

      // 5. ✨ 呼叫 RPC 程序：一次請求，後端自動完成核對與雙表 Transaction 寫入
      final response = await _supabase.rpc(
        'save_complete_deck',
        params: {
          'p_name': deckName,
          'p_series_id': detectedSeriesId,
          'p_cover_card_url': coverCardUrl,
          'p_cards': cardsJsonList, 
        },
      );

      debugPrint('🎉 牌組寫入成功！回傳結果: $response');
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;

    } catch (e) {
      debugPrint('儲存失敗詳情: $e');
      // 這裡會精準捕獲 PostgreSQL 拋出的 'RAISE EXCEPTION'
      String errorMsg = '🔥 資料庫同步失敗: $e';
      if (e.toString().contains('50')) {
        errorMsg = '伺服器校驗失敗：牌組必須剛好 50 張！';
      } else if (e.toString().contains('JWT')) {
        errorMsg = '登入過期，請重新登入';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMsg,
      );
      return false;
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

  Future<List<UACard>> fetchCardsForDeck(int deckId) async {
    try {
      // 🌟 核心關聯查詢：從 deck_cards 查出數量，並順便把 cards 內容與最新價格 View 撈出來
      final response = await _supabase
          .from('deck_cards')
          .select('quantity, cards(*, latest_prices(price_jpy))')
          .eq('deck_id', deckId);

      final List<UACard> expandedCards = [];

      for (var item in response) {
        final int quantity = item['quantity'] as int;
        final cardJson = item['cards'] as Map<String, dynamic>;

        // 使用我們之前寫好的 factory 轉換成物件
        final card = UACard.fromJson(cardJson);

        // 🔥 關鍵：根據數量（例如 x4），就把這張卡片重複加進 List 裡面 4 次
        // 這樣進到詳情頁時，總數才會是精準的 50 張，圖表計算才會正確！
        for (int i = 0; i < quantity; i++) {
          expandedCards.add(card);
        }
      }

      return expandedCards;
    } catch (e) {
      debugPrint('🚨 撈取牌組詳細卡片失敗: $e');
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