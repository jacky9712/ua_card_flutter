import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ua_card.dart';

abstract class CardRepository {
  Future<List<String>> fetchSeriesList();
  Future<List<UACard>> fetchCards({String? series, int limit = 60, int offset = 0});
  Future<List<UACard>> searchCards(String query, {int limit = 60, int offset = 0});
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
  Future<List<UACard>> fetchCards({String? series, int limit = 60, int offset = 0}) async {
    var query = _supabase.from('cards').select('*, latest_prices(price_jpy)');
    if (series != null && series.isNotEmpty && series != '全部系列') {
      query = query.ilike('card_number', '$series%');
    }
    // 改用 range 分頁，不再一次把整個系列/搜尋結果撈回來。
    final response = await query.order('card_number', ascending: true).range(offset, offset + limit - 1);
    return (response as List).map((json) => UACard.fromJson(json)).toList();
  }

  @override
  Future<List<UACard>> searchCards(String query, {int limit = 60, int offset = 0}) async {
    final response = await _supabase
        .from('cards')
        .select('*, latest_prices(price_jpy)')
        .or('card_number.ilike.%$query%,name.ilike.%$query%')
        .order('card_number', ascending: true)
        .range(offset, offset + limit - 1);
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
