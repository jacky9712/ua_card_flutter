import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ua_card.dart';

abstract class CardRepository {
  Future<List<String>> fetchSeriesList();
  Future<List<UACard>> fetchCards({String? series, int limit = 300});
  Future<List<UACard>> searchCards(String query, {int limit = 100});
  Future<List<UACard>> fetchCardsByNumbers(List<String> cardNumbers);
}

class SupabaseCardRepository implements CardRepository {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<String>> fetchSeriesList() async {
    final response = await _supabase.from('series').select('series_code').order('id');
    return (response as List).map((s) => s['series_code'].toString().toUpperCase()).toList();
  }

  @override
  Future<List<UACard>> fetchCards({String? series, int limit = 300}) async {
    var query = _supabase.from('cards').select('*, latest_prices(price_jpy)');
    if (series != null && series.isNotEmpty && series != '全部系列') {
      query = query.ilike('card_number', '$series%');
    }
    final response = await query.order('card_number', ascending: true).limit(limit);
    return (response as List).map((json) => UACard.fromJson(json)).toList();
  }

  @override
  Future<List<UACard>> searchCards(String query, {int limit = 100}) async {
    final response = await _supabase
        .from('cards')
        .select('*, latest_prices(price_jpy)')
        .or('card_number.ilike.%$query%,name.ilike.%$query%')
        .order('card_number', ascending: true)
        .limit(limit);
    return (response as List).map((json) => UACard.fromJson(json)).toList();
  }

  @override
  Future<List<UACard>> fetchCardsByNumbers(List<String> cardNumbers) async {
    if (cardNumbers.isEmpty) return [];
    
    final response = await _supabase
        .from('cards')
        .select('*, latest_prices(price_jpy)')
        .inFilter('card_number', cardNumbers);

    return (response as List).map((json) => UACard.fromJson(json)).toList();
  }
}
