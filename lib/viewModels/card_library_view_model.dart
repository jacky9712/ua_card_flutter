import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class CardLibraryState {
  final List<UACard> allCards;
  final List<UACard> filteredCards;
  final List<String> availableSeries;
  final String selectedSeries;
  final Set<String> selectedColors;
  final String searchQuery;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final AppError? error;

  CardLibraryState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.availableSeries = const [],
    this.selectedSeries = '',
    this.selectedColors = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  CardLibraryState copyWith({
    List<UACard>? allCards,
    List<UACard>? filteredCards,
    List<String>? availableSeries,
    String? selectedSeries,
    Set<String>? selectedColors,
    String? searchQuery,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    AppError? error,
  }) {
    return CardLibraryState(
      allCards: allCards ?? this.allCards,
      filteredCards: filteredCards ?? this.filteredCards,
      availableSeries: availableSeries ?? this.availableSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
      selectedColors: selectedColors ?? this.selectedColors,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class CardLibraryViewModel extends Notifier<CardLibraryState> {
  // 分頁狀態純內部追蹤，不放進 CardLibraryState：畫面不需要知道目前 offset 是多少，
  // 只需要 hasMore/isLoadingMore 就夠決定要不要顯示載入中。
  static const int _pageSize = 60;
  int _offset = 0;
  bool _isSearchMode = false; // 目前 allCards 是系列瀏覽來的還是關鍵字搜尋來的，loadMore() 要知道呼叫哪個 repo 方法

  // 🔥 賽跑保護：build() 會用 microtask 觸發 _initData()，同時並行抓系列清單與第一頁瀏覽
  // （卡片不再等系列清單）。provider 可能在首頁一顯示時就被 HomeScreen 建立、在背景預載，
  // 所以使用者從首頁搜尋框送出搜尋時，預載的 fetchCards() 很可能還在跑，跟 _remoteSearch()
  // 同時進行，誰後完成就用誰的結果覆蓋 allCards——如果是瀏覽的那次後完成，就會把「跟搜尋字
  // 完全無關的瀏覽結果」套用搜尋文字篩選，結果幾乎必定是空的，使用者體感就是「打名字找不到」。
  // 每次真正發起新的一輪查詢（fetchCards/_remoteSearch）就換一個 request id，
  // 非同步結果回來時如果 id 已經被更新的請求蓋過，直接丟棄，不寫回 state。
  int _requestId = 0;

  // 搜尋框每打一個字都會呼叫 updateSearchQuery，等使用者停手一小段時間再送遠端查詢。
  static const Duration searchDebounce = Duration(milliseconds: 300);
  Timer? _searchDebounceTimer;

  @override
  CardLibraryState build() {
    ref.onDispose(() => _searchDebounceTimer?.cancel());
    // fetchCards() 在第一個 await 前就會寫 state，build() 裡直接呼叫會讀到未初始化的 provider，
    // 所以延到 microtask（同 meta_view_model.dart 的做法）。
    Future.microtask(_initData);
    return CardLibraryState(isLoading: true);
  }

  void _initData() {
    if (!ref.mounted) return; // microtask 跑之前 provider 可能已經被 dispose
    // 系列清單只給篩選下拉選單用，不該擋住第一頁卡片：兩個並行抓。
    unawaited(_fetchSeriesList());
    unawaited(fetchCards());
  }

  Future<void> _fetchSeriesList() async {
    try {
      final repo = ref.read(cardRepositoryProvider);
      final list = await repo.fetchSeriesList();
      // 系列清單跟卡片並行，可能比失敗的卡片晚回來，不能把卡片的錯誤洗掉。
      state = state.copyWith(availableSeries: list, error: state.error);
    } catch (e) {
      debugPrint('載入系列失敗: $e');
    }
  }

  Future<void> fetchCards() async {
    final int myRequest = ++_requestId;
    _offset = 0;
    _isSearchMode = false;
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final cards = await repo.fetchCards(
        series: state.selectedSeries,
        colors: state.selectedColors.toList(),
        limit: _pageSize,
        offset: 0,
      );
      if (myRequest != _requestId) return; // 這筆結果已經被更新的查詢蓋過，丟棄
      state = state.copyWith(allCards: cards, isLoading: false, hasMore: cards.length == _pageSize);
      _applyFilters();
    } catch (e) {
      if (myRequest != _requestId) return;
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.dbConnectionFailed));
    }
  }

  /// 預載失敗（還沒有任何卡片、且留著錯誤）時重抓一次；組牌頁打開時呼叫。
  void retryIfInitialLoadFailed() {
    if (state.isLoading || state.allCards.isNotEmpty || state.error == null) return;
    if (_isSearchMode) {
      _remoteSearch(state.searchQuery);
    } else {
      fetchCards();
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);

    // 🔥 原本要打超過 2 個字才會觸發遠端搜尋，中日文卡名 2 個字往往就是很明確的關鍵字
    // （例如「紫雲」），卡在這個門檻下只會在「目前已經載入的那一小頁」裡面本地篩選，
    // 幾乎必定找不到——搜尋分頁後單頁資料量已經很小，不用再靠字數門檻擋遠端查詢。
    _searchDebounceTimer?.cancel();
    if (query.isNotEmpty) {
      _searchDebounceTimer = Timer(searchDebounce, () => _remoteSearch(query));
    } else if (_isSearchMode) {
      fetchCards(); // 清空搜尋字立刻回到系列瀏覽，不等 debounce；同時換 request id 丟棄還在飛的搜尋結果
    } else {
      _applyFilters();
    }
  }

  Future<void> _remoteSearch(String query) async {
    final int myRequest = ++_requestId;
    _offset = 0;
    _isSearchMode = true;
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final cards = await repo.searchCards(
        query,
        series: state.selectedSeries,
        colors: state.selectedColors.toList(),
        limit: _pageSize,
        offset: 0,
      );
      if (myRequest != _requestId) return;
      state = state.copyWith(allCards: cards, isLoading: false, hasMore: cards.length == _pageSize);
      _applyFilters();
    } catch (e) {
      if (myRequest != _requestId) return;
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.searchCardsFailed));
    }
  }

  /// 捲到底時載入下一頁，沿用目前是「系列瀏覽」還是「關鍵字搜尋」模式。
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    // 不換新的 request id（這是延續現有這輪查詢，不是新的一輪），但要記住目前的 id，
    // 如果等待期間有新的 fetchCards()/_remoteSearch() 蓋過去，這批結果就該丟棄。
    final int myRequest = _requestId;
    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final nextOffset = _offset + _pageSize;
      final colors = state.selectedColors.toList();
      final more = _isSearchMode
          ? await repo.searchCards(state.searchQuery, series: state.selectedSeries, colors: colors, limit: _pageSize, offset: nextOffset)
          : await repo.fetchCards(series: state.selectedSeries, colors: colors, limit: _pageSize, offset: nextOffset);
      if (myRequest != _requestId) return;
      _offset = nextOffset;
      state = state.copyWith(
        allCards: [...state.allCards, ...more],
        isLoadingMore: false,
        hasMore: more.length == _pageSize,
      );
      _applyFilters();
    } catch (e) {
      if (myRequest != _requestId) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void updateSelectedSeries(String s) {
    state = state.copyWith(selectedSeries: s);
    // 跟 updateSelectedColors 一樣：如果目前是關鍵字搜尋模式，換系列後要沿用
    // _remoteSearch 重新查，不然會掉回 fetchCards()（不帶搜尋字），變成只在
    // 新系列的第一頁裡對搜尋字做本地篩選，找不到頁外的結果。
    if (_isSearchMode) {
      _remoteSearch(state.searchQuery);
    } else {
      fetchCards();
    }
  }

  /// 🔥 顏色篩選改成伺服器端過濾（見 card_repository.dart），跟分頁搭配的話不能只篩
  /// 「目前已經載入的那一頁」——分頁上限只有 60 筆，選顏色前如果沒剛好捲到底，
  /// 符合顏色的卡片很可能根本還沒被載入，本地篩選只會篩出小貓兩三隻。選色後重新
  /// 發一輪查詢（沿用目前是系列瀏覽還是關鍵字搜尋模式），這樣才是對整個資料庫篩選。
  void updateSelectedColors(Set<String> colors) {
    state = state.copyWith(selectedColors: colors);
    if (_isSearchMode) {
      _remoteSearch(state.searchQuery);
    } else {
      fetchCards();
    }
  }

  // 顏色已經在伺服器端篩過了，這裡只需要再套用搜尋文字的本地篩選——主要是給「系列瀏覽」
  // 模式擋殘留的搜尋字用（系列瀏覽本身不帶搜尋字查詢），關鍵字搜尋模式下這裡本來就會全過。
  void _applyFilters() {
    Iterable<UACard> result = state.allCards;

    final lowerQuery = state.searchQuery.toLowerCase();
    if (lowerQuery.isNotEmpty) {
      result = result.where((card) {
        return card.cardNumber.toLowerCase().contains(lowerQuery) ||
            (card.name ?? '').toLowerCase().contains(lowerQuery);
      });
    }

    state = state.copyWith(filteredCards: result.toList());
  }
}

final cardLibraryViewModelProvider = NotifierProvider<CardLibraryViewModel, CardLibraryState>(() => CardLibraryViewModel());
