import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';

class MetaState {
  final List<Map<String, dynamic>> metaData;
  final bool isLoading;
  // series_popularity 是即時彙總的 view，資料新鮮度就是「最後一次成功抓取」的時間。
  // 以前畫面直接顯示 DateTime.now()，每次重建都會跳成當下時間，看起來永遠是剛更新。
  final DateTime? fetchedAt;
  // 最後一次抓取是否失敗。以前失敗時只把 isLoading 關掉，畫面就顯示「暫無資料」，
  // 網路斷線看起來跟真的沒資料一模一樣。
  final bool loadFailed;

  MetaState({
    this.metaData = const [],
    this.isLoading = false,
    this.fetchedAt,
    this.loadFailed = false,
  });

  MetaState copyWith({
    List<Map<String, dynamic>>? metaData,
    bool? isLoading,
    DateTime? fetchedAt,
    bool? loadFailed,
  }) {
    return MetaState(
      metaData: metaData ?? this.metaData,
      isLoading: isLoading ?? this.isLoading,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      loadFailed: loadFailed ?? this.loadFailed,
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
    Future.microtask(fetchMetaEnvironment);
    return MetaState();
  }

  Future<void> fetchMetaEnvironment() async {
    try {
      state = state.copyWith(isLoading: true);
      final repo = ref.read(metaRepositoryProvider);
      final data = await repo.fetchEnvironmentData();
      state = state.copyWith(metaData: data, isLoading: false, fetchedAt: DateTime.now(), loadFailed: false);
    } catch (e) {
      debugPrint('載入對戰環境失敗: $e');
      state = state.copyWith(isLoading: false, loadFailed: true);
    }
  }
}

final metaViewModelProvider = NotifierProvider<MetaViewModel, MetaState>(() => MetaViewModel());
