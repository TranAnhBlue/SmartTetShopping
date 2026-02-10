class ItemModel {
  final int? id;
  final String name;
  final int? categoryId;
  final int quantity;
  final double estimatedPrice;
  final bool isBought;

  ItemModel({
    this.id,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.estimatedPrice,
    this.isBought = false,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      categoryId: map['category_id'] as int?,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      estimatedPrice:
      (map['estimated_price'] as num?)?.toDouble() ?? 0,
      isBought: (map['is_bought'] ?? 0) == 1,
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'quantity': quantity,
      'estimated_price': estimatedPrice,
      'is_bought': isBought ? 1 : 0,
    };
  }
}
