import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ua_card.dart';

abstract class CardRepository {
  Future<List<String>> fetchSeriesList();
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0});
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0});
  Future<List<UACard>> fetchCardsByNumbers(List<String> cardNumbers);
}

class SupabaseCardRepository implements CardRepository {
  final _supabase = Supabase.instance.client;

  // 顏色現在跟分頁搭配，不能只在已經抓回來的那一頁裡篩（見 fetchCards/searchCards 的呼叫端說明），
  // 要在伺服器端一起篩。用 ilike（不帶 %）做不分大小寫的精確比對，因為 DB 裡的 color
  // 欄位大小寫不一定統一（既有的本地篩選邏輯到處都用 .toUpperCase() 防呆，這裡也比照辦理）。
  String? _colorOrFilter(List<String>? colors) {
    if (colors == null || colors.isEmpty) return null;
    return colors.map((c) => 'color.ilike.$c').join(',');
  }

  @override
  Future<List<String>> fetchSeriesList() async {
    final response = await _supabase.from('series').select('series_code').order('id');
    return (response as List).map((s) => s['series_code'].toString().toUpperCase()).toList();
  }

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    var query = _supabase.from('cards').select('*, latest_prices(price_jpy)');
    if (series != null && series.isNotEmpty && series != '全部系列') {
      query = query.ilike('card_number', '$series%');
    }
    final colorFilter = _colorOrFilter(colors);
    if (colorFilter != null) {
      query = query.or(colorFilter);
    }
    // 改用 range 分頁，不再一次把整個系列/搜尋結果撈回來。
    final response = await query.order('card_number', ascending: true).range(offset, offset + limit - 1);
    return (response as List).map((json) => UACard.fromJson(json)).toList();
  }

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    var q = _supabase
        .from('cards')
        .select('*, latest_prices(price_jpy)')
        .or('card_number.ilike.%$query%,name.ilike.%$query%');
    // 系列篩選原本沒接進來，套了系列篩選（不管自動帶入還是手動選）後只要打字搜尋，
    // 就會忽略系列限制、變成整個資料庫下去搜──跟 fetchCards() 一樣補上 series 條件。
    if (series != null && series.isNotEmpty && series != '全部系列') {
      q = q.ilike('card_number', '$series%');
    }
    final colorFilter = _colorOrFilter(colors);
    if (colorFilter != null) {
      q = q.or(colorFilter);
    }
    final response = await q.order('card_number', ascending: true).range(offset, offset + limit - 1);
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
