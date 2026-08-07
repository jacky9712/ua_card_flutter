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
  final String? errorMessage;

  CardLibraryState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.availableSeries = const [],
    this.selectedSeries = '',
    this.selectedColors = const {},
    this.searchQuery = '',
    this.isLoading = false,
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
      errorMessage: errorMessage,
    );
  }
}

class CardLibraryViewModel extends Notifier<CardLibraryState> {
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
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final cards = await repo.fetchCards(series: state.selectedSeries);
      state = state.copyWith(allCards: cards, isLoading: false);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '資料庫連線失敗');
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);

    // 如果想要即時從遠端搜尋 (Debounce 更好，這裡先簡單實作)
    if (query.length > 2) {
      _remoteSearch(query);
    } else {
      _applyFilters();
    }
  }

  Future<void> _remoteSearch(String query) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final cards = await repo.searchCards(query);
      state = state.copyWith(allCards: cards, isLoading: false);
      _applyFilters();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSelectedSeries(String s) {
    state = state.copyWith(selectedSeries: s);
    fetchCards();
  }

  void updateSelectedColors(Set<String> colors) {
    state = state.copyWith(selectedColors: colors);
    _applyFilters();
  }

  // 統一在這裡套用「顏色」與「搜尋文字」這兩個純 client 端篩選，
  // 讓不管卡池是從哪個管道進來的（系列查詢 / 遠端搜尋）都套用同一套規則。
  void _applyFilters() {
    Iterable<UACard> result = state.allCards;

    if (state.selectedColors.isNotEmpty) {
      result = result.where((card) => state.selectedColors.contains((card.color ?? '').toUpperCase()));
    }

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
