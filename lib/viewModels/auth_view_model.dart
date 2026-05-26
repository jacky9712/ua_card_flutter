import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/providers.dart';

class UserAuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  UserAuthState({this.user, this.isLoading = false, this.errorMessage});

  bool get isRealUser => user != null && user!.appMetadata['provider'] != 'anonymous';
  bool get isLoggedIn => user != null;

  UserAuthState copyWith({User? user, bool? isLoading, String? errorMessage}) {
    return UserAuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
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
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(authRepositoryProvider).signUp(email, password);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(authRepositoryProvider).signInAnonymously();
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, UserAuthState>(() => AuthViewModel());
