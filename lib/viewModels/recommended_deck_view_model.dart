import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ua_card.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class RecommendedDeckState {
  final List<Map<String, dynamic>> decks;
  final bool isLoading;
  final AppError? error;

  RecommendedDeckState({
    this.decks = const [],
    this.isLoading = false,
    this.error,
  });

  RecommendedDeckState copyWith({
    List<Map<String, dynamic>>? decks,
    bool? isLoading,
    AppError? error,
  }) {
    return RecommendedDeckState(
      decks: decks ?? this.decks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RecommendedDeckViewModel extends Notifier<RecommendedDeckState> {
  @override
  RecommendedDeckState build() {
    // 不能在 build() 還沒 return 前就同步觸發會修改 state 的 async function
    // （fetchRecommendedDecks 一開始就設定 isLoading），會讓 Riverpod 丟出
    // "Tried to read the state of an uninitialized provider"。用 Future.microtask
    // 延到 build() 真正 return 之後再執行（同樣的錯誤模式也出現在既有的
    // MetaViewModel，一併修正過了）。
    Future.microtask(fetchRecommendedDecks);
    return RecommendedDeckState();
  }

  Future<void> fetchRecommendedDecks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(recommendedDeckRepositoryProvider);
      final list = await repo.fetchRecommendedDecks();
      state = state.copyWith(decks: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.loadTopDecksFailed, detail: '$e'));
    }
  }

  Future<List<UACard>> fetchCardsForDeck(int deckId) async {
    final repo = ref.read(recommendedDeckRepositoryProvider);
    return repo.fetchRecommendedDeckCards(deckId);
  }
}

final recommendedDeckViewModelProvider =
    NotifierProvider<RecommendedDeckViewModel, RecommendedDeckState>(() => RecommendedDeckViewModel());
