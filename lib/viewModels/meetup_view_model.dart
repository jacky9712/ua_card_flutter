import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/providers.dart';
import '../utils/location_platform.dart';

enum MeetupSortMode { soonest, nearest }

class MeetupState {
  final List<Map<String, dynamic>> posts;
  final bool isLoading;
  final String? errorMessage;
  final MeetupSortMode sortMode;
  final Position? myPosition;

  MeetupState({
    this.posts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.sortMode = MeetupSortMode.soonest,
    this.myPosition,
  });

  MeetupState copyWith({
    List<Map<String, dynamic>>? posts,
    bool? isLoading,
    String? errorMessage,
    MeetupSortMode? sortMode,
    Position? myPosition,
  }) {
    return MeetupState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
  @override
  MeetupState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchOpenMeetupPosts);
    return MeetupState();
  }

  Future<void> fetchOpenMeetupPosts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(meetupRepositoryProvider);
      final posts = await repo.fetchOpenMeetupPosts();
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入約戰貼文失敗');
    }
  }

  /// 切到「最近距離」排序時才真的去要定位權限——不要一進畫面就跳權限詢問。
  Future<void> setSortMode(MeetupSortMode mode) async {
    if (mode == MeetupSortMode.nearest && state.myPosition == null) {
      final position = await getCurrentPositionOrNull();
      if (position == null) {
        state = state.copyWith(errorMessage: '無法取得目前位置，改用時間排序');
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
    state = state.copyWith(isLoading: true, errorMessage: null);
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
      state = state.copyWith(isLoading: false, errorMessage: '發布失敗: $e');
      return false;
    }
  }

  Future<void> deleteMeetupPost(int id) async {
    try {
      final repo = ref.read(meetupRepositoryProvider);
      await repo.deleteMeetupPost(id);
      await fetchOpenMeetupPosts();
    } catch (e) {
      state = state.copyWith(errorMessage: '刪除失敗: $e');
    }
  }
}

final meetupViewModelProvider = NotifierProvider<MeetupViewModel, MeetupState>(() => MeetupViewModel());
