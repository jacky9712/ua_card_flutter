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
    fetchRanking();
    fetchMetaEnvironment();
    return MetaState();
  }

  Future<void> fetchRanking() async {
    try {
      final repo = ref.read(metaRepositoryProvider);
      final list = await repo.fetchRanking();
      state = state.copyWith(rankingList: list);
    } catch (e) {
      print('載入排行失敗: $e');
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
