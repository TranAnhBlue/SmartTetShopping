class ShoppingItem {

  final int? id;
  final String name;
  final int? categoryId;
  final int quantity;
  final double estimatedPrice;
  final bool isBought;
  final String? imageUrl;

  ShoppingItem({
    this.id,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.estimatedPrice,
    this.isBought = false,
    this.imageUrl,
  });

  double get totalCost => quantity * estimatedPrice;
}
