import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';
import 'card_repository.dart';
import 'deck_repository.dart';
import 'meta_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => SupabaseAuthRepository());
final cardRepositoryProvider = Provider<CardRepository>((ref) => SupabaseCardRepository());
final deckRepositoryProvider = Provider<DeckRepository>((ref) => MixedDeckRepository());
final metaRepositoryProvider = Provider<MetaRepository>((ref) => SupabaseMetaRepository());
