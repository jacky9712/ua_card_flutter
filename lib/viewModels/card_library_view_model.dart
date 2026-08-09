import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import '../repositories/providers.dart';

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
  final String? errorMessage;

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
    this.errorMessage,
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
    String? errorMessage,
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
      errorMessage: errorMessage,
    );
  }
}

class CardLibraryViewModel extends Notifier<CardLibraryState> {
  // 分頁狀態純內部追蹤，不放進 CardLibraryState：畫面不需要知道目前 offset 是多少，
  // 只需要 hasMore/isLoadingMore 就夠決定要不要顯示載入中。
  static const int _pageSize = 60;
  int _offset = 0;
  bool _isSearchMode = false; // 目前 allCards 是系列瀏覽來的還是關鍵字搜尋來的，loadMore() 要知道呼叫哪個 repo 方法

  // 🔥 賽跑保護：冷啟動時 build() 會非同步觸發 _initData()（先抓系列、再抓第一頁瀏覽），
  // 如果使用者在這個還沒跑完的當下就直接打關鍵字搜尋（例如從首頁搜尋框第一次進來，
  // provider 剛初始化），_initData() 裡的 fetchCards() 跟 _remoteSearch() 會同時在跑，
  // 誰後完成就用誰的結果覆蓋 allCards——如果是瀏覽的那次後完成，就會把「跟搜尋字完全
  // 無關的瀏覽結果」套用搜尋文字篩選，結果幾乎必定是空的，使用者體感就是「打名字找不到」。
  // 每次真正發起新的一輪查詢（fetchCards/_remoteSearch）就換一個 request id，
  // 非同步結果回來時如果 id 已經被更新的請求蓋過，直接丟棄，不寫回 state。
  int _requestId = 0;

  @override
  CardLibraryState build() {
    _initData();
    return CardLibraryState(isLoading: true);
  }

  Future<void> _initData() async {
    await _fetchSeriesList();
    await fetchCards();
  }

  Future<void> _fetchSeriesList() async {
    try {
      final repo = ref.read(cardRepositoryProvider);
      final list = await repo.fetchSeriesList();
      state = state.copyWith(availableSeries: list);
    } catch (e) {
      print('載入系列失敗: $e');
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
      state = state.copyWith(isLoading: false, errorMessage: '資料庫連線失敗');
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);

    // 🔥 原本要打超過 2 個字才會觸發遠端搜尋，中日文卡名 2 個字往往就是很明確的關鍵字
    // （例如「紫雲」），卡在這個門檻下只會在「目前已經載入的那一小頁」裡面本地篩選，
    // 幾乎必定找不到——搜尋分頁後單頁資料量已經很小，不用再靠字數門檻擋遠端查詢。
    if (query.isNotEmpty) {
      _remoteSearch(query);
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
        colors: state.selectedColors.toList(),
        limit: _pageSize,
        offset: 0,
      );
      if (myRequest != _requestId) return;
      state = state.copyWith(allCards: cards, isLoading: false, hasMore: cards.length == _pageSize);
      _applyFilters();
    } catch (e) {
      if (myRequest != _requestId) return;
      state = state.copyWith(isLoading: false);
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
          ? await repo.searchCards(state.searchQuery, colors: colors, limit: _pageSize, offset: nextOffset)
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
    fetchCards();
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
