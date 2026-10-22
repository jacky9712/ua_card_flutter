import 'dart:async';

import 'package:flutter/foundation.dart';
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
  // 進行中的請求共用同一個 Future（同 card_library_view_model.dart 的 _seriesRequest），
  // 重複呼叫 fetchRecommendedDecks 不會發出兩個互相覆蓋的請求。
  Future<void>? _inFlight;
  // true 代表 decks 已經是網路結果，晚到的快取不得再覆蓋。
  bool _hasNetworkData = false;

  @override
  RecommendedDeckState build() {
    // 不能在 build() 還沒 return 前就同步觸發會修改 state 的 async function
    // （fetchRecommendedDecks 一開始就設定 isLoading），會讓 Riverpod 丟出
    // "Tried to read the state of an uninitialized provider"。用 Future.microtask
    // 延到 build() 真正 return 之後再執行（同樣的錯誤模式也出現在既有的
    // MetaViewModel，一併修正過了）。
    Future.microtask(_init);
    // 初始就是載入中，第一格不會閃「目前尚無推薦牌組」。
    return RecommendedDeckState(isLoading: true);
  }

  void _init() {
    if (!ref.mounted) return; // microtask 跑之前 provider 可能已經被 dispose
    unawaited(fetchRecommendedDecks());
    unawaited(_restoreCache());
  }

  Future<void> _restoreCache() async {
    List<Map<String, dynamic>>? cached;
    try {
      cached = await ref.read(recommendedDeckCacheStoreProvider).loadDecks();
    } catch (e) {
      debugPrint('讀取推薦牌組快取失敗: $e');
      return;
    }
    if (!ref.mounted) return;
    // 只在網路還沒給資料時套用。isLoading 由 copyWith 保留（網路還在跑就維持 true）；
    // error 清成 null：網路先失敗、快取後到時，有快取就不算失敗。
    if (cached != null && cached.isNotEmpty && !_hasNetworkData && state.decks.isEmpty) {
      state = state.copyWith(decks: cached, error: null);
    }
  }

  Future<void> fetchRecommendedDecks() => _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await ref.read(recommendedDeckRepositoryProvider).fetchRecommendedDecks();
      if (!ref.mounted) return;
      _hasNetworkData = true;
      state = state.copyWith(decks: list, isLoading: false);
      // 只存非空結果（同 card_library_view_model.dart）。
      if (list.isNotEmpty) unawaited(ref.read(recommendedDeckCacheStoreProvider).saveDecks(list));
    } catch (e) {
      if (!ref.mounted) return;
      // 已經有資料（快取或上一次的網路結果）時背景更新失敗：保留清單、不設 error。
      if (state.decks.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }
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
