class ShoppingItem {

  final int? id;
  final String name;
  final int? categoryId;
  final int quantity;
  final double estimatedPrice;
  final bool isBought;

  ShoppingItem({
    this.id,
    required this.name,
    this.categoryId,
    required this.quantity,
    required this.estimatedPrice,
    this.isBought = false,
  });

  double get totalCost => quantity * estimatedPrice;
}
