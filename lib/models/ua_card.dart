// lib/models/ua_card.dart

class UACard {
  final int? id;               // 資料庫的 ID
  final int? seriesId;
  final String cardNumber;
  final String? name;
  final String? rarity;

  // 🔥 新增這三個稀有度特徵欄位
  final bool isParallel;
  final int starCount;
  final bool hasSignature;

  final String? color;
  final String? imageUrl;

  // 遊戲數值
  final String? cardType;
  final int? bp;
  final int? apCost;
  final int? energyReq;
  final int? energyGenerated;
  final List<String>? tags;
  final String? effectText;
  final String? triggerText;

  // 價格
  final int? price;

  UACard({
    this.id,
    this.seriesId,
    required this.cardNumber,
    this.name,
    this.rarity,

    // 給予預設值
    this.isParallel = false,
    this.starCount = 0,
    this.hasSignature = false,

    this.color,
    this.imageUrl,
    this.cardType,
    this.bp,
    this.apCost,
    this.energyReq,
    this.energyGenerated,
    this.tags,
    this.effectText,
    this.triggerText,
    this.price,
  });

  factory UACard.fromJson(Map<String, dynamic> json) {
    // 處理來自 latest_prices View 的價格
    int? parsedPrice;
    if (json['latest_prices'] != null) {
      // Supabase 關聯查詢有時候會回傳 List，有時候是 Map，這裡做雙重相容
      if (json['latest_prices'] is List && (json['latest_prices'] as List).isNotEmpty) {
        parsedPrice = ((json['latest_prices'][0]['price_jpy'] ?? 0) as num).toInt();
      } else if (json['latest_prices'] is Map) {
        parsedPrice = ((json['latest_prices']['price_jpy'] ?? 0) as num).toInt();
      }
    }

    return UACard(
      id: json['id'] as int?,
      seriesId: json['series_id'] as int?,
      cardNumber: json['card_number'] ?? 'Unknown',
      name: json['name'],
      rarity: json['rarity'],

      // 🔥 對應你最新的 DB Schema，加上預設值防呆
      isParallel: json['is_parallel'] ?? false,
      starCount: json['star_count'] ?? 0,
      hasSignature: json['has_signature'] ?? false,

      color: json['color'],
      imageUrl: json['image_url'],
      cardType: json['card_type'],
      bp: json['bp'] as int?,
      apCost: json['ap_cost'] ?? 1,
      energyReq: json['energy_req'] ?? 0,
      energyGenerated: json['energy_generated'] ?? 0,

      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      effectText: json['effect_text'],
      triggerText: json['trigger_text'],
      price: parsedPrice,
    );
  }
}