import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import '../repositories/providers.dart';

class CardLibraryState {
  final List<UACard> allCards;
  final List<UACard> filteredCards;
  final List<String> availableSeries;
  final String selectedSeries;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  CardLibraryState({
    this.allCards = const [],
    this.filteredCards = const [],
    this.availableSeries = const [],
    this.selectedSeries = '',
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  CardLibraryState copyWith({
    List<UACard>? allCards,
    List<UACard>? filteredCards,
    List<String>? availableSeries,
    String? selectedSeries,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CardLibraryState(
      allCards: allCards ?? this.allCards,
      filteredCards: filteredCards ?? this.filteredCards,
      availableSeries: availableSeries ?? this.availableSeries,
      selectedSeries: selectedSeries ?? this.selectedSeries,
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
      state = state.copyWith(allCards: cards, filteredCards: cards, isLoading: false);
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
      _applyLocalSearch();
    }
  }

  Future<void> _remoteSearch(String query) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(cardRepositoryProvider);
      final cards = await repo.searchCards(query);
      state = state.copyWith(allCards: cards, filteredCards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSelectedSeries(String s) {
    state = state.copyWith(selectedSeries: s);
    fetchCards();
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
}

final cardLibraryViewModelProvider = NotifierProvider<CardLibraryViewModel, CardLibraryState>(() => CardLibraryViewModel());
