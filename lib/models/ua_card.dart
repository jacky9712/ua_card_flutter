
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
  });

  // 對應 Kotlin 的 @SerialName，把 JSON 轉成 Dart 物件
  factory UACard.fromJson(Map<String, dynamic> json) {
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
    );
  }
}