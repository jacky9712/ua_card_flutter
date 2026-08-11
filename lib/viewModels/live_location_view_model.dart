import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';
import '../utils/location_platform.dart';

class LiveLocationState {
  final bool isSharing;
  final DateTime? sharingUntil;
  final List<Map<String, dynamic>> nearbyOthers;
  final bool isLoading;
  final String? errorMessage;

  LiveLocationState({
    this.isSharing = false,
    this.sharingUntil,
    this.nearbyOthers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LiveLocationState copyWith({
    bool? isSharing,
    DateTime? sharingUntil,
    bool clearSharingUntil = false,
    List<Map<String, dynamic>>? nearbyOthers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LiveLocationState(
      isSharing: isSharing ?? this.isSharing,
      sharingUntil: clearSharingUntil ? null : (sharingUntil ?? this.sharingUntil),
      nearbyOthers: nearbyOthers ?? this.nearbyOthers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LiveLocationViewModel extends Notifier<LiveLocationState> {
  Timer? _pingTimer;

  @override
  LiveLocationState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(fetchNearbyOthers);
    // provider 被丟棄時（例如畫面關掉、狀態重置）順便把還在跑的 Timer 停掉，
    // 不然背景會一直嘗試更新一個沒人在看的分享狀態。
    ref.onDispose(() => _pingTimer?.cancel());
    return LiveLocationState();
  }

  Future<void> fetchNearbyOthers() async {
    if (!isLocationCapablePlatform) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(liveLocationRepositoryProvider);
      final all = await repo.fetchActiveLiveLocations();
      state = state.copyWith(nearbyOthers: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入附近玩家失敗');
    }
  }

  Future<bool> startSharing(Duration duration) async {
    if (!isLocationCapablePlatform) {
      state = state.copyWith(errorMessage: '此裝置平台不支援定位分享');
      return false;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);

    final until = DateTime.now().add(duration);
    final success = await _pingOnce(until);
    if (!success) {
      state = state.copyWith(isLoading: false, errorMessage: '無法取得目前位置，請確認定位權限已開啟');
      return false;
    }

    state = state.copyWith(isSharing: true, sharingUntil: until, isLoading: false);

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      if (DateTime.now().isAfter(until)) {
        await stopSharing();
        return;
      }
      await _pingOnce(until);
    });
    return true;
  }

  Future<bool> _pingOnce(DateTime until) async {
    final position = await getCurrentPositionOrNull();
    if (position == null) return false;
    try {
      final repo = ref.read(liveLocationRepositoryProvider);
      await repo.upsertMyLocation(lat: position.latitude, lng: position.longitude, expiresAt: until);
      await fetchNearbyOthers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopSharing() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      final repo = ref.read(liveLocationRepositoryProvider);
      await repo.stopSharing();
    } catch (_) {
      // 停止分享失敗也不用擋使用者的 UI，本地狀態照樣切回「未分享」。
    }
    state = state.copyWith(isSharing: false, clearSharingUntil: true);
    await fetchNearbyOthers();
  }
}

final liveLocationViewModelProvider =
    NotifierProvider<LiveLocationViewModel, LiveLocationState>(() => LiveLocationViewModel());
