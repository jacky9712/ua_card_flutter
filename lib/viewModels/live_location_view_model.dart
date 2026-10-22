import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/providers.dart';
import '../utils/location_platform.dart';
import '../utils/app_error.dart';

class LiveLocationState {
  final bool isSharing;
  final DateTime? sharingUntil;
  final List<Map<String, dynamic>> nearbyOthers;
  final bool isLoading;
  final AppError? error;

  LiveLocationState({
    this.isSharing = false,
    this.sharingUntil,
    this.nearbyOthers = const [],
    this.isLoading = false,
    this.error,
  });

  LiveLocationState copyWith({
    bool? isSharing,
    DateTime? sharingUntil,
    bool clearSharingUntil = false,
    List<Map<String, dynamic>>? nearbyOthers,
    bool? isLoading,
    AppError? error,
  }) {
    return LiveLocationState(
      isSharing: isSharing ?? this.isSharing,
      sharingUntil: clearSharingUntil ? null : (sharingUntil ?? this.sharingUntil),
      nearbyOthers: nearbyOthers ?? this.nearbyOthers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LiveLocationViewModel extends Notifier<LiveLocationState> {
  Timer? _pingTimer;

  @override
  LiveLocationState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，見 profile_view_model.dart 的註解。
    Future.microtask(() async {
      await _restoreSharing();
      if (!ref.mounted) return;
      await fetchNearbyOthers();
    });
    // provider 被丟棄時（例如畫面關掉、狀態重置）順便把還在跑的 Timer 停掉，
    // 不然背景會一直嘗試更新一個沒人在看的分享狀態。
    ref.onDispose(() => _pingTimer?.cancel());
    return LiveLocationState();
  }

  /// App 重開（或 provider 重建）時，伺服器上的位置在到期前都還是公開的；
  /// 不恢復的話畫面會顯示「未分享」、停止按鈕也不見，使用者沒辦法關掉。
  Future<void> _restoreSharing() async {
    if (!isLocationCapablePlatform) return;
    try {
      final until = await ref.read(liveLocationRepositoryProvider).fetchMySharingUntil();
      // await 期間 provider 可能已經被丟棄（畫面關掉、容器 dispose），之後就不能再碰 state / ref。
      if (!ref.mounted) return;
      if (until == null || !DateTime.now().isBefore(until)) return;
      state = state.copyWith(isSharing: true, sharingUntil: until);
      _startPingTimer(until);
    } catch (_) {
      // 查不到就當作沒在分享，不擋畫面。
    }
  }

  Future<void> fetchNearbyOthers() async {
    if (!isLocationCapablePlatform) return;
    state = state.copyWith(isLoading: true, error: state.error.clearedIf(AppErrorCode.loadNearbyFailed));
    try {
      final repo = ref.read(liveLocationRepositoryProvider);
      final all = await repo.fetchActiveLiveLocations();
      if (!ref.mounted) return;
      state = state.copyWith(
        nearbyOthers: all,
        isLoading: false,
        error: state.error.clearedIf(AppErrorCode.loadNearbyFailed),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.loadNearbyFailed));
    }
  }

  Future<bool> startSharing(Duration duration) async {
    if (!isLocationCapablePlatform) {
      state = state.copyWith(error: const AppError(AppErrorCode.locationNotSupported));
      return false;
    }
    state = state.copyWith(isLoading: true, error: null);

    final until = DateTime.now().add(duration);
    final success = await _pingOnce(until);
    if (!ref.mounted) return false;
    if (!success) {
      state = state.copyWith(isLoading: false, error: const AppError(AppErrorCode.locationUnavailable));
      return false;
    }

    state = state.copyWith(isSharing: true, sharingUntil: until, isLoading: false);
    _startPingTimer(until);
    return true;
  }

  void _startPingTimer(DateTime until) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      if (DateTime.now().isAfter(until)) {
        await stopSharing();
        return;
      }
      await _pingOnce(until);
    });
  }

  Future<bool> _pingOnce(DateTime until) async {
    final position = await ref.read(currentPositionProvider)();
    if (position == null || !ref.mounted) return false;
    try {
      final repo = ref.read(liveLocationRepositoryProvider);
      await repo.upsertMyLocation(lat: position.latitude, lng: position.longitude, expiresAt: until);
      if (!ref.mounted) return false;
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
    if (!ref.mounted) return;
    state = state.copyWith(isSharing: false, clearSharingUntil: true);
    await fetchNearbyOthers();
  }
}

final liveLocationViewModelProvider =
    NotifierProvider<LiveLocationViewModel, LiveLocationState>(() => LiveLocationViewModel());
