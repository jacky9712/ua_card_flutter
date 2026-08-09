import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/providers.dart';

class ProfileState {
  final String? displayName;
  final bool isLoading;
  final String? errorMessage;

  ProfileState({this.displayName, this.isLoading = false, this.errorMessage});

  ProfileState copyWith({String? displayName, bool? isLoading, String? errorMessage}) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // 🔥 build() 不能同步呼叫會馬上改 state 的 async function，不然 Riverpod
    // 會丟出 "uninitialized provider"、拖垮呼叫端整個畫面（這個 session 踩過兩次）。
    Future.microtask(fetchMyProfile);
    return ProfileState();
  }

  Future<void> fetchMyProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.fetchProfile(userId);
      state = state.copyWith(displayName: profile?['display_name'] as String?, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '載入個人資料失敗');
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateDisplayName(displayName);
      state = state.copyWith(displayName: displayName, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: '更新暱稱失敗: $e');
      return false;
    }
  }
}

final profileViewModelProvider = NotifierProvider<ProfileViewModel, ProfileState>(() => ProfileViewModel());
