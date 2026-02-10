class ItemPrice {

  final int? id;
  final int itemId;
  final int marketId;
  final double price;

  ItemPrice({
    this.id,
    required this.itemId,
    required this.marketId,
    required this.price,
  });
}
