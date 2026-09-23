import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/providers.dart';
import '../utils/app_error.dart';

class UserAuthState {
  final User? user;
  final bool isLoading;
  final AppError? error;

  UserAuthState({this.user, this.isLoading = false, this.error});

  // 🔥 修正：檢查是否為匿名使用者
  bool get isRealUser => user != null && !user!.isAnonymous;
  bool get isLoggedIn => user != null;

  UserAuthState copyWith({User? user, bool? isLoading, AppError? error}) {
    return UserAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthViewModel extends Notifier<UserAuthState> {
  @override
  UserAuthState build() {
    final repo = ref.read(authRepositoryProvider);
    repo.onAuthStateChange.listen((data) {
      state = state.copyWith(user: data.session?.user);
    });
    return UserAuthState(user: repo.currentUser);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.authFailed, detail: '$e'));
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).signUp(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.authFailed, detail: '$e'));
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.signOut();
      // 登出後立即建立新的匿名階段，確保 App 核心功能（本地組牌）不中斷
      await repo.signInAnonymously();
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: AppError(AppErrorCode.signOutFailed, detail: '$e'));
    }
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, UserAuthState>(() => AuthViewModel());
