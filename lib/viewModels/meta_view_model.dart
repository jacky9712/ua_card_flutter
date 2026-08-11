import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';

class MetaState {
  final List<Map<String, dynamic>> rankingList;
  final List<Map<String, dynamic>> metaData;
  final bool isLoading;

  MetaState({
    this.rankingList = const [],
    this.metaData = const [],
    this.isLoading = false,
  });

  MetaState copyWith({
    List<Map<String, dynamic>>? rankingList,
    List<Map<String, dynamic>>? metaData,
    bool? isLoading,
  }) {
    return MetaState(
      rankingList: rankingList ?? this.rankingList,
      metaData: metaData ?? this.metaData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MetaViewModel extends Notifier<MetaState> {
  @override
  MetaState build() {
    // 🔥 不能在 build() 還沒 return 前就同步觸發會修改 state 的 async function
    // （fetchMetaEnvironment 一開始就 `state = state.copyWith(isLoading: true)`），
    // 否則 Riverpod 會丟出 "Tried to read the state of an uninitialized provider"，
    // 而且會讓整個呼叫 ref.watch(metaViewModelProvider) 的畫面（HomeScreen）直接建構失敗。
    // 用 Future.microtask 延到 build() 真正 return、provider 完成初始化之後再執行。
    Future.microtask(() {
      fetchRanking();
      fetchMetaEnvironment();
    });
    return MetaState();
  }

  Future<void> fetchRanking() async {
    try {
      final repo = ref.read(metaRepositoryProvider);
      final list = await repo.fetchRanking();
      state = state.copyWith(rankingList: list);
    } catch (e) {
      debugPrint('載入排行失敗: $e');
    }
  }

  Future<void> fetchMetaEnvironment() async {
    try {
      state = state.copyWith(isLoading: true);
      final repo = ref.read(metaRepositoryProvider);
      final data = await repo.fetchEnvironmentData();
      state = state.copyWith(metaData: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final metaViewModelProvider = NotifierProvider<MetaViewModel, MetaState>(() => MetaViewModel());
