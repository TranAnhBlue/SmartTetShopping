class PriceModel {

  final int? id;
  final int itemId;
  final int marketId;
  final double price;

  PriceModel({
    this.id,
    required this.itemId,
    required this.marketId,
    required this.price,
  });

  factory PriceModel.fromMap(Map<String, dynamic> map) {
    return PriceModel(
      id: map['id'] as int?,
      itemId: (map['item_id'] as num?)?.toInt() ?? 0,
      marketId: (map['market_id'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'market_id': marketId,
      'price': price,
    };
  }
}
