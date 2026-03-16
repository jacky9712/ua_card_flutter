
class UACard {
  final int? id;
  final String cardNumber;
  final String? imageUrl;
  final String? color;
  final int? bp;
  final int? apCost;
  final String? effectText;
  final String? triggerText;
  final String? name;
  final String? rarity;
  final int? price;

  UACard({
    this.id,
    this.cardNumber = '',
    this.imageUrl,
    this.color,
    this.bp,
    this.apCost,
    this.effectText,
    this.triggerText,
    this.name,
    this.rarity,
    this.price,
  });

  // 對應 Kotlin 的 @SerialName，把 JSON 轉成 Dart 物件
  factory UACard.fromJson(Map<String, dynamic> json) {
    // 🔥 新增這段：解析從 latest_prices 表格 Join 過來的價格
    int? parsedPrice;

    // 檢查 JSON 裡面有沒有 latest_prices 的資料
    if (json['latest_prices'] != null) {
      final lp = json['latest_prices'];
      if (lp is List && lp.isNotEmpty) {
        // 🔥 修正：這裡也要改成 price_jpy
        parsedPrice = (lp[0]['price_jpy'] as num?)?.toInt();
      } else if (lp is Map) {
        // 🔥 修正：這裡也要改成 price_jpy
        parsedPrice = (lp['price_jpy'] as num?)?.toInt();
      }
    }
    return UACard(
      id: json['id'] as int?,
      cardNumber: json['card_number'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      color: json['color'] as String?,
      bp: json['bp'] as int?,
      apCost: json['ap_cost'] as int?,
      effectText: json['effect_text'] as String?,
      triggerText: json['trigger_text'] as String?,
      name: json['name'] as String?,
      rarity: json['rarity'] as String?,
      price: parsedPrice,
    );
  }
}