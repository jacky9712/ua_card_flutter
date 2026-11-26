import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/providers.dart';
import '../utils/location_platform.dart';
import '../utils/app_error.dart';

enum MeetupSortMode { soonest, nearest }

class MeetupState {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final AppError? error;
  final MeetupSortMode sortMode;
  final Position? myPosition;

  MeetupState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.sortMode = MeetupSortMode.soonest,
    this.myPosition,
  });

  MeetupState copyWith({
    List<Map<String, dynamic>>? posts,
    bool? isLoading,
    AppError? error,
    MeetupSortMode? sortMode,
    Position? myPosition,
  }) {
    return MeetupState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sortMode: sortMode ?? this.sortMode,
      myPosition: myPosition ?? this.myPosition,
    );
  }

  /// 依目前的排序模式回傳排好的清單；「最近距離」在還沒拿到自己座標，
  /// 或某筆貼文本身沒填經緯度時，會自然掉回原本的時間序（不會噴例外或漏資料）。
  List<Map<String, dynamic>> get sortedPosts {
    if (sortMode == MeetupSortMode.soonest || myPosition == null) return posts;
    final withDistance = posts.map((p) {
      final lat = p['lat'] as double?;
      final lng = p['lng'] as double?;
      final distance = (lat == null || lng == null)
          ? double.infinity
          : Geolocator.distanceBetween(myPosition!.latitude, myPosition!.longitude, lat, lng);
      return MapEntry(p, distance);
    }).toList();
    withDistance.sort((a, b) => a.value.compareTo(b.value));
    return withDistance.map((e) => e.key).toList();
  }
}

class MeetupViewModel extends Notifier<MeetupState> {
  Timer? _debounce;

  /// 短時間內多筆變動（例如自己剛發布、又觸發 realtime）合併成一次重抓。
  void _onRemoteChange() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _refreshSilently);
  }

  /// 背景重抓：不切 isLoading（避免清單閃轉圈）、失敗也不蓋掉畫面上的錯誤訊息。
  Future<void> _refreshSilently() async {
    try {
      final posts = await ref.read(meetupRepositoryProvider).fetchOpenMeetupPosts();
      state = state.copyWith(posts: posts, error: state.error);
    } catch (_) {}
  }

  @override
  MeetupState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchOpenMeetupPosts);
    // 別人新增/修改/取消貼文時即時反映在清單上，不用手動下拉重新整理。
    final unsubscribe = ref.read(meetupRepositoryProvider).subscribeToChanges(_onRemoteChange);
    ref.onDispose(() {
      _debounce?.cancel();
      unsubscribe();
    });
    return MeetupState();
  }

  Future<void> fetchOpenMeetupPosts() async {
    state = state.copyWith(isLoading: true, error: state.error.clearedIf(AppErrorCode.loadMeetupsFailed));
    try {
      final repo = ref.read(meetupRepositoryProvider);
      final posts = await repo.fetchOpenMeetupPosts();
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        error: state.error.clearedIf(AppErrorCode.loadMeetupsFailed),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.loadMeetupsFailed));
    }
  }

  /// 切到「最近距離」排序時才真的去要定位權限——不要一進畫面就跳權限詢問。
  Future<void> setSortMode(MeetupSortMode mode) async {
    if (mode == MeetupSortMode.nearest && state.myPosition == null) {
      final position = await ref.read(currentPositionProvider)();
      if (position == null) {
        state = state.copyWith(error: const AppError(AppErrorCode.locationFallbackToTime));
        return;
      }
      state = state.copyWith(myPosition: position);
    }
    state = state.copyWith(sortMode: mode);
  }

  Future<bool> createMeetupPost({
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(meetupRepositoryProvider);
      await repo.createMeetupPost(
        locationName: locationName,
        lat: lat,
        lng: lng,
        note: note,
        scheduledAt: scheduledAt,
        deckId: deckId,
        deckNameSnapshot: deckNameSnapshot,
        deckTier: deckTier,
      );
      await fetchOpenMeetupPosts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.publishFailed, detail: '$e'));
      return false;
    }
  }

  Future<bool> updateMeetupPost({
    required int id,
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(meetupRepositoryProvider);
      await repo.updateMeetupPost(
        id: id,
        locationName: locationName,
        lat: lat,
        lng: lng,
        note: note,
        scheduledAt: scheduledAt,
        deckId: deckId,
        deckNameSnapshot: deckNameSnapshot,
        deckTier: deckTier,
      );
      await fetchOpenMeetupPosts();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.updateFailed, detail: '$e'));
      return false;
    }
  }

  Future<bool> deleteMeetupPost(int id) async {
    try {
      final repo = ref.read(meetupRepositoryProvider);
      await repo.deleteMeetupPost(id);
    } catch (e) {
      state = state.copyWith(error: AppError(AppErrorCode.deleteFailed, detail: '$e'));
      return false;
    }
    await fetchOpenMeetupPosts();
    return true;
  }
}

final meetupViewModelProvider = NotifierProvider<MeetupViewModel, MeetupState>(() => MeetupViewModel());
