/// 卡片查詢實際會用到的欄位（UACard.fromJson 讀、且 model 以外有人用的）。
/// 新增 UACard 會用到的欄位時要同步加在這裡，test/card_columns_test.dart 會檢查。
const String cardSelectColumns =
    'id, series_id, card_number, name, color, image_url, bp, ap_cost, '
    'energy_req, effect_text, trigger_text, latest_prices(price_jpy)';
