import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  User? get currentUser;
  Stream<AuthState> get onAuthStateChange;
  Future<void> signInAnonymously();
  Future<void> signInWithPassword(String email, String password);
  Future<void> signUp(String email, String password);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  final _supabase = Supabase.instance.client;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  Future<void> signInAnonymously() async {
    await _supabase.auth.signInAnonymously();
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
